-- Migration: Add likes_count column to polls table and toggle_poll_like function
-- This adds like functionality to polls with anonymous like counting

-- 1. Add likes_count column to polls table
ALTER TABLE polls ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0;

-- 2. Create function to toggle poll likes
CREATE OR REPLACE FUNCTION toggle_poll_like(p_poll_id INTEGER)
RETURNS VOID AS $$
BEGIN
    -- Simply increment the likes_count by 1
    -- In a real scenario, you might want to track user sessions,
    -- but for simplicity, we just increment/decrement
    -- The frontend will handle the toggle logic
    UPDATE polls 
    SET likes_count = likes_count + 1 
    WHERE id = p_poll_id;
    
    -- If no rows were updated, the poll doesn't exist
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Poll with id % not found', p_poll_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Alternative function that handles both increment and decrement
CREATE OR REPLACE FUNCTION toggle_poll_like_advanced(p_poll_id INTEGER, p_increment BOOLEAN DEFAULT TRUE)
RETURNS INTEGER AS $$
DECLARE
    new_likes_count INTEGER;
BEGIN
    IF p_increment THEN
        -- Increment likes
        UPDATE polls 
        SET likes_count = likes_count + 1 
        WHERE id = p_poll_id
        RETURNING likes_count INTO new_likes_count;
    ELSE
        -- Decrement likes (but don't go below 0)
        UPDATE polls 
        SET likes_count = GREATEST(likes_count - 1, 0)
        WHERE id = p_poll_id
        RETURNING likes_count INTO new_likes_count;
    END IF;
    
    -- If no rows were updated, the poll doesn't exist
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Poll with id % not found', p_poll_id;
    END IF;
    
    RETURN new_likes_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Simple increment/decrement functions
CREATE OR REPLACE FUNCTION increment_poll_likes(p_poll_id INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN toggle_poll_like_advanced(p_poll_id, TRUE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION decrement_poll_likes(p_poll_id INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN toggle_poll_like_advanced(p_poll_id, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Update existing polls to have likes_count = 0 if NULL
UPDATE polls SET likes_count = 0 WHERE likes_count IS NULL;