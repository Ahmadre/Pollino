-- Fix für poll_options sequence synchronization
-- Dieses Skript behebt den Fehler "duplicate key value violates unique constraint poll_options_pkey"

DO $$
DECLARE
    max_id INTEGER;
BEGIN
    -- Finde die höchste ID in der poll_options Tabelle
    SELECT COALESCE(MAX(id), 0) INTO max_id FROM poll_options;
    
    -- Setze die Sequenz auf den nächsten verfügbaren Wert
    PERFORM setval('poll_options_id_seq', max_id + 1, false);
    
    RAISE NOTICE 'poll_options sequence synchronized to %', max_id + 1;
END $$;