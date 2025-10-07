-- Migration: Fix timezone handling for poll expiration
-- Date: 2025-10-07

-- Convert expires_at from TIMESTAMP to TIMESTAMPTZ (UTC storage)
-- This ensures consistent timezone handling across all timestamp columns

DO $$
BEGIN
    -- Check if expires_at column exists and is timestamp without time zone
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'polls' 
        AND column_name = 'expires_at' 
        AND data_type = 'timestamp without time zone'
    ) THEN
        -- Convert existing data to UTC and change column type
        -- Assume existing timestamps were meant to be UTC (since DB runs in UTC)
        ALTER TABLE polls 
        ALTER COLUMN expires_at TYPE TIMESTAMP WITH TIME ZONE 
        USING expires_at AT TIME ZONE 'UTC';
        
        RAISE NOTICE 'Converted expires_at column from TIMESTAMP to TIMESTAMPTZ';
    ELSE
        RAISE NOTICE 'expires_at column is already TIMESTAMPTZ or does not exist';
    END IF;
END $$;

-- Update all poll-related functions to handle TIMESTAMPTZ properly
CREATE OR REPLACE FUNCTION get_poll_status(poll_id UUID)
RETURNS TABLE (
  id UUID,
  is_active BOOLEAN,
  is_expired BOOLEAN,
  expires_at TIMESTAMPTZ,
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

-- Enhanced function to help with timezone conversions in the API
CREATE OR REPLACE FUNCTION get_poll_with_timezone_info(poll_id BIGINT, user_timezone TEXT DEFAULT 'UTC')
RETURNS TABLE (
  id BIGINT,
  title TEXT,
  description TEXT,
  created_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  expires_at_user_tz TIMESTAMP,
  auto_delete_after_expiry BOOLEAN,
  is_expired BOOLEAN,
  time_until_expiry INTERVAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.title,
    p.description,
    p.created_at,
    p.expires_at,
    -- Convert to user's timezone for display
    CASE 
      WHEN p.expires_at IS NOT NULL THEN 
        (p.expires_at AT TIME ZONE user_timezone)::TIMESTAMP
      ELSE NULL
    END AS expires_at_user_tz,
    p.auto_delete_after_expiry,
    -- Check if expired
    CASE 
      WHEN p.expires_at IS NULL THEN FALSE
      WHEN p.expires_at <= NOW() THEN TRUE
      ELSE FALSE
    END AS is_expired,
    -- Time until expiry
    CASE 
      WHEN p.expires_at IS NULL THEN NULL
      WHEN p.expires_at > NOW() THEN (p.expires_at - NOW())
      ELSE INTERVAL '0'
    END AS time_until_expiry
  FROM polls p
  WHERE p.id = poll_id;
END;
$$ LANGUAGE plpgsql;

-- Function to convert user timezone input to UTC for storage
CREATE OR REPLACE FUNCTION convert_user_datetime_to_utc(
  user_datetime TIMESTAMP, 
  user_timezone TEXT DEFAULT 'UTC'
) RETURNS TIMESTAMPTZ AS $$
BEGIN
  -- Convert user's local datetime to UTC for storage
  RETURN (user_datetime AT TIME ZONE user_timezone) AT TIME ZONE 'UTC';
END;
$$ LANGUAGE plpgsql;

-- Function to get current time in user's timezone
CREATE OR REPLACE FUNCTION get_current_time_in_timezone(user_timezone TEXT DEFAULT 'UTC')
RETURNS TIMESTAMP AS $$
BEGIN
  RETURN (NOW() AT TIME ZONE user_timezone)::TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Update comments for documentation
COMMENT ON COLUMN polls.expires_at IS 'Timestamp when the poll expires in UTC. NULL means no expiration. Always stored as TIMESTAMPTZ (UTC).';
COMMENT ON FUNCTION get_poll_with_timezone_info(BIGINT, TEXT) IS 'Returns poll information with timezone conversion for user display.';
COMMENT ON FUNCTION convert_user_datetime_to_utc(TIMESTAMP, TEXT) IS 'Converts user local datetime to UTC for database storage.';
COMMENT ON FUNCTION get_current_time_in_timezone(TEXT) IS 'Returns current time in specified timezone for user display.';

-- Create a view for easier timezone handling in queries
CREATE OR REPLACE VIEW polls_with_timezone_info AS
SELECT 
  p.*,
  CASE 
    WHEN p.expires_at IS NULL THEN FALSE
    WHEN p.expires_at <= NOW() THEN TRUE
    ELSE FALSE
  END AS is_expired,
  CASE 
    WHEN p.expires_at IS NULL THEN NULL
    WHEN p.expires_at > NOW() THEN (p.expires_at - NOW())
    ELSE INTERVAL '0'
  END AS time_until_expiry
FROM polls p;

COMMENT ON VIEW polls_with_timezone_info IS 'View that includes timezone-aware expiration status and time calculations.';