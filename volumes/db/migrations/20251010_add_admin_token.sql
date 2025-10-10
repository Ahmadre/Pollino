-- Migration: Admin Token für Umfragen-Administration hinzufügen
-- Datum: 2025-10-10
-- Beschreibung: Fügt admin_token Feld hinzu für sichere Admin-URLs zur Umfragen-Verwaltung

BEGIN;

-- Aktiviere pgcrypto Extension für gen_random_bytes()
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

-- Gewähre Ausführungsrechte auf pgcrypto-Funktionen für anon und authenticated Rollen
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- Funktion zum Generieren eines neuen Admin-Tokens mit pgcrypto und Fallback
CREATE OR REPLACE FUNCTION generate_admin_token()
RETURNS TEXT AS $$
DECLARE
    result TEXT;
    chars TEXT := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    i INTEGER;
BEGIN
    -- Versuche zuerst pgcrypto zu verwenden
    BEGIN
        result := encode(gen_random_bytes(32), 'hex');
        RETURN result;
    EXCEPTION
        WHEN undefined_function OR insufficient_privilege THEN
            -- Fallback: Generiere Token mit Standard-PostgreSQL-Funktionen
            result := '';
            FOR i IN 1..64 LOOP
                result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
            END LOOP;
            RETURN result;
    END;
END;
$$ LANGUAGE plpgsql;

-- Füge admin_token Spalte zur polls Tabelle hinzu
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'polls' AND column_name = 'admin_token'
    ) THEN
        ALTER TABLE polls ADD COLUMN admin_token TEXT UNIQUE;
        
        -- Erstelle Index für bessere Performance bei Admin-Token Lookups
        CREATE INDEX IF NOT EXISTS idx_polls_admin_token ON polls(admin_token);
        
        -- Generiere admin_token für alle bestehenden Umfragen
        UPDATE polls 
        SET admin_token = generate_admin_token()
        WHERE admin_token IS NULL;
        
        -- Mache admin_token NOT NULL für zukünftige Einträge
        ALTER TABLE polls ALTER COLUMN admin_token SET NOT NULL;
        
        RAISE NOTICE 'Admin token column added to polls table with tokens generated for existing polls';
    ELSE
        RAISE NOTICE 'Admin token column already exists, skipping migration';
    END IF;
END $$;

-- Trigger zum automatischen Generieren von Admin-Tokens bei neuen Umfragen
CREATE OR REPLACE FUNCTION set_admin_token()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.admin_token IS NULL THEN
        NEW.admin_token := generate_admin_token();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Erstelle Trigger nur wenn er nicht bereits existiert
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_poll_admin_token') THEN
        CREATE TRIGGER set_poll_admin_token
            BEFORE INSERT ON polls
            FOR EACH ROW EXECUTE FUNCTION set_admin_token();
    END IF;
END $$;

-- Funktion zur Validierung von Admin-Tokens
CREATE OR REPLACE FUNCTION validate_admin_token(poll_id BIGINT, token TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    stored_token TEXT;
BEGIN
    SELECT admin_token INTO stored_token 
    FROM polls 
    WHERE id = poll_id;
    
    RETURN stored_token IS NOT NULL AND stored_token = token;
END;
$$ LANGUAGE plpgsql;

COMMIT;