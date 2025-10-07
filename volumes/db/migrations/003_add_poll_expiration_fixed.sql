-- Migration: Add expiration functionality to polls
-- Date: 2024-01-20
-- Fixed version for Synology NAS deployment

-- Add expiration columns to polls table (only if they don't exist)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'polls' AND column_name = 'expires_at') THEN
        ALTER TABLE polls ADD COLUMN expires_at TIMESTAMP;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'polls' AND column_name = 'auto_delete_after_expiry') THEN
        ALTER TABLE polls ADD COLUMN auto_delete_after_expiry BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Create function to get poll status
CREATE OR REPLACE FUNCTION get_poll_status(poll_id UUID)
RETURNS TABLE (
  id UUID,
  is_active BOOLEAN,
  is_expired BOOLEAN,
  expires_at TIMESTAMP,
  auto_delete_after_expiry BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    CASE 
      WHEN p.expires_at IS NULL THEN TRUE
      WHEN p.expires_at > NOW() THEN TRUE
      ELSE FALSE
    END AS is_active,
    CASE 
      WHEN p.expires_at IS NULL THEN FALSE
      WHEN p.expires_at <= NOW() THEN TRUE
      ELSE FALSE
    END AS is_expired,
    p.expires_at,
    p.auto_delete_after_expiry
  FROM polls p
  WHERE p.id = poll_id;
END;
$$ LANGUAGE plpgsql;

-- Create simple cleanup function (single parameter for backward compatibility)
CREATE OR REPLACE FUNCTION cleanup_expired_polls()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER := 0;
BEGIN
  -- Delete polls that are expired and have auto_delete_after_expiry = true
  DELETE FROM polls 
  WHERE expires_at IS NOT NULL 
    AND expires_at <= NOW() 
    AND auto_delete_after_expiry = true;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Create index for better performance on expiration queries (only if they don't exist)
CREATE INDEX IF NOT EXISTS idx_polls_expires_at ON polls(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_polls_auto_delete ON polls(auto_delete_after_expiry) WHERE auto_delete_after_expiry = true;

-- Create a maintenance table to track cleanup operations
CREATE TABLE IF NOT EXISTS poll_cleanup_log (
  id SERIAL PRIMARY KEY,
  cleanup_time TIMESTAMP DEFAULT NOW(),
  deleted_count INTEGER,
  triggered_by TEXT DEFAULT 'system'
);

-- Enhanced cleanup function with logging and batch processing (two parameters)
CREATE OR REPLACE FUNCTION cleanup_expired_polls_with_log(trigger_source TEXT DEFAULT 'system', batch_size INTEGER DEFAULT 100)
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER := 0;
  total_deleted INTEGER := 0;
  poll_ids_to_delete UUID[];
BEGIN
  -- Process in batches to avoid long-running transactions
  LOOP
    -- Get a batch of expired poll IDs
    SELECT ARRAY(
      SELECT id FROM polls 
      WHERE expires_at IS NOT NULL 
        AND expires_at <= NOW() 
        AND auto_delete_after_expiry = true
      ORDER BY expires_at ASC
      LIMIT batch_size
    ) INTO poll_ids_to_delete;
    
    -- Exit if no more polls to delete
    IF array_length(poll_ids_to_delete, 1) IS NULL THEN
      EXIT;
    END IF;
    
    -- Delete the batch
    DELETE FROM polls WHERE id = ANY(poll_ids_to_delete);
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    total_deleted := total_deleted + deleted_count;
    
    -- Exit if we deleted fewer than the batch size (last batch)
    IF deleted_count < batch_size THEN
      EXIT;
    END IF;
  END LOOP;
  
  -- Log the cleanup operation if polls were deleted
  IF total_deleted > 0 THEN
    INSERT INTO poll_cleanup_log (deleted_count, triggered_by) 
    VALUES (total_deleted, trigger_source);
    
    -- Log to PostgreSQL log for monitoring
    RAISE NOTICE 'Poll cleanup completed: % polls deleted by %', total_deleted, trigger_source;
  END IF;
  
  RETURN total_deleted;
END;
$$ LANGUAGE plpgsql;

-- Overloaded function with single parameter for backward compatibility
CREATE OR REPLACE FUNCTION cleanup_expired_polls_with_log(trigger_source TEXT)
RETURNS INTEGER AS $$
BEGIN
  RETURN cleanup_expired_polls_with_log(trigger_source, 100);
END;
$$ LANGUAGE plpgsql;

-- Function to check if cleanup is needed (based on time and pending expired polls)
CREATE OR REPLACE FUNCTION should_run_cleanup()
RETURNS BOOLEAN AS $$
DECLARE
  last_cleanup TIMESTAMP;
  cleanup_interval INTERVAL := '15 minutes'::INTERVAL; -- More frequent cleanup
  pending_count INTEGER;
BEGIN
  -- Check if there are any expired polls waiting to be deleted
  SELECT COUNT(*) INTO pending_count
  FROM polls 
  WHERE expires_at IS NOT NULL 
    AND expires_at <= NOW() 
    AND auto_delete_after_expiry = true
  LIMIT 1;
  
  -- If no pending polls, no need to run cleanup
  IF pending_count = 0 THEN
    RETURN FALSE;
  END IF;
  
  -- Get the last cleanup time
  SELECT MAX(cleanup_time) INTO last_cleanup FROM poll_cleanup_log;
  
  -- Run cleanup if no cleanup has been done or it's been more than the interval
  RETURN (last_cleanup IS NULL OR (NOW() - last_cleanup) > cleanup_interval);
END;
$$ LANGUAGE plpgsql;

-- Main periodic cleanup function
CREATE OR REPLACE FUNCTION run_automatic_poll_cleanup()
RETURNS INTEGER AS $$
BEGIN
  -- Only run if cleanup is actually needed
  IF should_run_cleanup() THEN
    RETURN cleanup_expired_polls_with_log('auto-trigger', 100);
  ELSE
    RETURN 0;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to trigger cleanup when polls are accessed/modified
CREATE OR REPLACE FUNCTION trigger_cleanup_on_activity()
RETURNS TRIGGER AS $$
BEGIN
  -- Asynchronously trigger cleanup (non-blocking)
  PERFORM pg_notify('poll_cleanup_needed', 'trigger');
  
  -- For INSERT/UPDATE triggers, return NEW, for DELETE return OLD
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create triggers on polls table to detect activity and trigger cleanup
DROP TRIGGER IF EXISTS trigger_cleanup_on_poll_activity ON polls;
CREATE TRIGGER trigger_cleanup_on_poll_activity
  AFTER INSERT OR UPDATE OR DELETE ON polls
  FOR EACH ROW
  EXECUTE FUNCTION trigger_cleanup_on_activity();

-- Comments for documentation
COMMENT ON COLUMN polls.expires_at IS 'Timestamp when the poll expires. NULL means no expiration.';
COMMENT ON COLUMN polls.auto_delete_after_expiry IS 'Whether to automatically delete the poll after it expires.';
COMMENT ON FUNCTION get_poll_status(UUID) IS 'Returns the status information of a poll including expiration state.';
COMMENT ON FUNCTION cleanup_expired_polls() IS 'Simple cleanup function - deletes all expired polls that have auto_delete_after_expiry set to true.';
COMMENT ON FUNCTION cleanup_expired_polls_with_log(TEXT, INTEGER) IS 'Enhanced cleanup function with logging support and batch processing.';
COMMENT ON FUNCTION cleanup_expired_polls_with_log(TEXT) IS 'Single parameter version of cleanup function for backward compatibility.';
COMMENT ON FUNCTION run_automatic_poll_cleanup() IS 'Runs cleanup if more than 15 minutes have passed since last cleanup.';
COMMENT ON TABLE poll_cleanup_log IS 'Tracks automatic poll cleanup operations with timestamps and counts.';