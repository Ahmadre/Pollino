-- PostgreSQL Funktion zur automatischen Sequenz-Synchronisation
-- Diese Funktion kann von der Flutter App aufgerufen werden

CREATE OR REPLACE FUNCTION fix_poll_options_sequence()
RETURNS VOID AS $$
DECLARE
    max_id INTEGER;
    next_val INTEGER;
BEGIN
    -- Finde die höchste ID in der poll_options Tabelle
    SELECT COALESCE(MAX(id), 0) INTO max_id FROM poll_options;
    
    -- Setze die Sequenz auf den nächsten verfügbaren Wert
    PERFORM setval('poll_options_id_seq', max_id + 1, false);
    
    -- Hole den neuen Sequenzwert zur Bestätigung
    SELECT last_value INTO next_val FROM poll_options_id_seq;
    
    RAISE NOTICE 'poll_options sequence synchronized: max_id=%, next_val=%', max_id, next_val;
END;
$$ LANGUAGE plpgsql;