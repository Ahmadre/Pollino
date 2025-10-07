-- Migration: Erweitere bestehende Datenbank um User-Management Features
-- Erstellt am: 2025-10-07
-- Beschreibung: Fügt users Tabelle hinzu und erweitert polls/user_votes um Namens-Features

-- 1. Erstelle users Tabelle falls nicht vorhanden
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Erweitere polls Tabelle um neue Spalten
DO $$
BEGIN
    -- Füge created_by Spalte hinzu (falls nicht vorhanden)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='polls' AND column_name='created_by') THEN
        ALTER TABLE polls ADD COLUMN created_by UUID NULL REFERENCES users(id);
    END IF;

    -- Füge created_by_name Spalte hinzu (falls nicht vorhanden)  
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='polls' AND column_name='created_by_name') THEN
        ALTER TABLE polls ADD COLUMN created_by_name TEXT NULL;
    END IF;

    -- Füge is_anonymous Spalte hinzu (falls nicht vorhanden)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='polls' AND column_name='is_anonymous') THEN
        ALTER TABLE polls ADD COLUMN is_anonymous BOOLEAN DEFAULT TRUE;
    END IF;
END $$;

-- 3. Erweitere user_votes Tabelle um neue Spalten
DO $$
BEGIN
    -- Füge voter_name Spalte hinzu (falls nicht vorhanden)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_votes' AND column_name='voter_name') THEN
        ALTER TABLE user_votes ADD COLUMN voter_name TEXT NULL;
    END IF;

    -- Füge is_anonymous Spalte hinzu (falls nicht vorhanden)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_votes' AND column_name='is_anonymous') THEN
        ALTER TABLE user_votes ADD COLUMN is_anonymous BOOLEAN DEFAULT TRUE;
    END IF;
END $$;

-- 4. Aktualisiere user_id Spalte um users Referenz zu verwenden (falls noch nicht vorhanden)
DO $$
BEGIN
    -- Prüfe ob Foreign Key Constraint existiert
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name LIKE '%user_votes_user_id_fkey%') THEN
        -- Falls user_id Spalte UUID ist, füge Foreign Key hinzu
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_votes' AND column_name='user_id' AND data_type='uuid') THEN
            ALTER TABLE user_votes ADD CONSTRAINT user_votes_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES users(id);
        END IF;
    END IF;
END $$;

-- 5. Füge neue Constraints hinzu (falls nicht vorhanden)
DO $$
BEGIN
    -- Unique constraint für (poll_id, voter_name)
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'user_votes_poll_id_voter_name_key') THEN
        ALTER TABLE user_votes ADD CONSTRAINT user_votes_poll_id_voter_name_key 
            UNIQUE(poll_id, voter_name);
    END IF;
END $$;

-- 6. Erstelle/aktualisiere Indizes
CREATE INDEX IF NOT EXISTS idx_user_votes_voter_name ON user_votes(voter_name);
CREATE INDEX IF NOT EXISTS idx_users_name ON users(name);
CREATE INDEX IF NOT EXISTS idx_polls_created_by ON polls(created_by);

-- 7. Erstelle oder aktualisiere Funktionen
CREATE OR REPLACE FUNCTION create_or_get_user(user_name TEXT)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Versuche den Benutzer zu finden
    SELECT id INTO user_uuid FROM users WHERE name = user_name;
    
    -- Falls nicht gefunden, erstelle neuen Benutzer
    IF user_uuid IS NULL THEN
        INSERT INTO users (name) VALUES (user_name) RETURNING id INTO user_uuid;
    END IF;
    
    RETURN user_uuid;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cast_vote(
    p_poll_id BIGINT,
    p_option_id BIGINT,
    p_user_name TEXT DEFAULT NULL,
    p_is_anonymous BOOLEAN DEFAULT TRUE
)
RETURNS VOID AS $$
DECLARE
    user_uuid UUID;
    existing_vote INTEGER;
BEGIN
    -- Prüfe ob die Option zur Umfrage gehört
    IF NOT EXISTS (SELECT 1 FROM poll_options WHERE id = p_option_id AND poll_id = p_poll_id) THEN
        RAISE EXCEPTION 'Option % gehört nicht zur Umfrage %', p_option_id, p_poll_id;
    END IF;
    
    IF NOT p_is_anonymous AND p_user_name IS NOT NULL THEN
        -- Für nicht-anonyme Abstimmungen
        user_uuid := create_or_get_user(p_user_name);
        
        -- Prüfe ob der Benutzer bereits abgestimmt hat
        SELECT COUNT(*) INTO existing_vote 
        FROM user_votes 
        WHERE poll_id = p_poll_id AND (user_id = user_uuid OR voter_name = p_user_name);
        
        IF existing_vote > 0 THEN
            RAISE EXCEPTION 'Benutzer % hat bereits für Umfrage % abgestimmt', p_user_name, p_poll_id;
        END IF;
        
        -- Erstelle Abstimmungseintrag
        INSERT INTO user_votes (poll_id, option_id, user_id, voter_name, is_anonymous)
        VALUES (p_poll_id, p_option_id, user_uuid, p_user_name, FALSE);
    ELSE
        -- Für anonyme Abstimmungen
        INSERT INTO user_votes (poll_id, option_id, is_anonymous)
        VALUES (p_poll_id, p_option_id, TRUE);
    END IF;
    
    -- Erhöhe Stimmenzahl
    UPDATE poll_options SET votes = votes + 1 WHERE id = p_option_id;
END;
$$ LANGUAGE plpgsql;

-- 8. Füge Beispiel-Benutzer hinzu (nur wenn noch keine existieren)
INSERT INTO users (name) 
SELECT 'Max Mustermann' 
WHERE NOT EXISTS (SELECT 1 FROM users WHERE name = 'Max Mustermann');

INSERT INTO users (name) 
SELECT 'Anna Schmidt' 
WHERE NOT EXISTS (SELECT 1 FROM users WHERE name = 'Anna Schmidt');

INSERT INTO users (name) 
SELECT 'Tom Entwickler' 
WHERE NOT EXISTS (SELECT 1 FROM users WHERE name = 'Tom Entwickler');

-- 9. Aktualisiere bestehende Polls auf anonyme Umfragen (falls is_anonymous NULL ist)
UPDATE polls 
SET is_anonymous = TRUE 
WHERE is_anonymous IS NULL;

-- 10. Setze created_by_name für existierende nicht-anonyme Umfragen
UPDATE polls 
SET created_by_name = 'Max Mustermann'
WHERE id = 2 AND created_by_name IS NULL;

COMMIT;