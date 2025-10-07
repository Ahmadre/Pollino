-- Migration für Multiple Voting Support
-- Datum: 7. Oktober 2025

-- 1. Füge allows_multiple_votes Spalte zu polls Tabelle hinzu
ALTER TABLE polls ADD COLUMN IF NOT EXISTS allows_multiple_votes BOOLEAN DEFAULT FALSE;

-- 2. Entferne die Unique Constraints von user_votes für Multiple Voting
-- (Diese werden jetzt über die cast_vote Funktion gehandhabt)
ALTER TABLE user_votes DROP CONSTRAINT IF EXISTS user_votes_poll_id_user_id_key;
ALTER TABLE user_votes DROP CONSTRAINT IF EXISTS user_votes_poll_id_voter_name_key;

-- 3. Aktualisiere die cast_vote Funktion für Multiple Voting Support
-- (Wird automatisch durch polls_schema.sql überschrieben)

-- 4. Optional: Setze einige Beispiel-Umfragen auf Multiple Voting
-- UPDATE polls SET allows_multiple_votes = TRUE WHERE title LIKE '%Framework%' OR title LIKE '%Skills%';

-- Bestätige Migration
SELECT 'Multiple Voting Migration erfolgreich angewendet' as migration_status;