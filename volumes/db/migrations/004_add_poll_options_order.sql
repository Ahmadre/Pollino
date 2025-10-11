-- Migration: Add order column to poll_options table
-- Date: 2025-10-11
-- Description: Adds an order column to support drag & drop reordering of poll options

-- Add order column to poll_options table (only if it doesn't exist)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'poll_options' AND column_name = 'option_order') THEN
        ALTER TABLE poll_options ADD COLUMN option_order INTEGER DEFAULT 0;
    END IF;
END $$;

-- Update existing poll_options to have sequential order based on their id
-- This ensures existing polls maintain their current order
UPDATE poll_options 
SET option_order = subquery.row_number 
FROM (
    SELECT id, ROW_NUMBER() OVER (PARTITION BY poll_id ORDER BY id) as row_number
    FROM poll_options
    WHERE option_order = 0 OR option_order IS NULL
) AS subquery
WHERE poll_options.id = subquery.id;

-- Create index for better performance when ordering by option_order
CREATE INDEX IF NOT EXISTS idx_poll_options_order ON poll_options(poll_id, option_order);

-- Comment for documentation
COMMENT ON COLUMN poll_options.option_order IS 'Order of the option within the poll (ascending). Used for drag & drop reordering.';