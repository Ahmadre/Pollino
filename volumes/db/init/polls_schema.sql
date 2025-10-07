-- Tabelle für Benutzer (mit Name als eindeutigem Identifier)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabelle für Umfragen
CREATE TABLE IF NOT EXISTS polls (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID NULL REFERENCES users(id),
    created_by_name TEXT NULL,
    is_anonymous BOOLEAN DEFAULT TRUE,
    allows_multiple_votes BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE
);

-- Füge allows_multiple_votes Spalte hinzu falls sie nicht existiert (für bestehende DBs)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'polls' AND column_name = 'allows_multiple_votes'
    ) THEN
        ALTER TABLE polls ADD COLUMN allows_multiple_votes BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Tabelle für Umfrageoptionen
CREATE TABLE IF NOT EXISTS poll_options (
    id BIGSERIAL PRIMARY KEY,
    poll_id BIGINT NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    votes INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabelle für Benutzerabstimmungen
CREATE TABLE IF NOT EXISTS user_votes (
    id BIGSERIAL PRIMARY KEY,
    poll_id BIGINT NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    option_id BIGINT NOT NULL REFERENCES poll_options(id) ON DELETE CASCADE,
    user_id UUID NULL REFERENCES users(id),
    voter_name TEXT NULL,
    is_anonymous BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    -- Unique constraints werden über erweiterte cast_vote Funktion gehandhabt
);

-- Funktion zur Erhöhung der Stimmenzahl
CREATE OR REPLACE FUNCTION increment_votes(option_id BIGINT)
RETURNS VOID AS $$
BEGIN
    UPDATE poll_options 
    SET votes = votes + 1 
    WHERE id = option_id;
END;
$$ LANGUAGE plpgsql;

-- Funktion zum Erstellen oder Finden eines Benutzers
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

-- Funktion zum sicheren Abstimmen mit Multiple Voting Support
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
    poll_allows_multiple BOOLEAN;
    existing_option_vote INTEGER;
BEGIN
    -- Prüfe ob die Option zur Umfrage gehört und hole Multiple Vote Setting
    SELECT allows_multiple_votes INTO poll_allows_multiple 
    FROM polls 
    WHERE id = p_poll_id;
    
    IF poll_allows_multiple IS NULL THEN
        RAISE EXCEPTION 'Umfrage % nicht gefunden', p_poll_id;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM poll_options WHERE id = p_option_id AND poll_id = p_poll_id) THEN
        RAISE EXCEPTION 'Option % gehört nicht zur Umfrage %', p_option_id, p_poll_id;
    END IF;
    
    IF NOT p_is_anonymous AND p_user_name IS NOT NULL THEN
        -- Für nicht-anonyme Abstimmungen
        user_uuid := create_or_get_user(p_user_name);
        
        IF NOT poll_allows_multiple THEN
            -- Single Voting: Prüfe ob der Benutzer bereits abgestimmt hat
            SELECT COUNT(*) INTO existing_vote 
            FROM user_votes 
            WHERE poll_id = p_poll_id AND (user_id = user_uuid OR voter_name = p_user_name);
            
            IF existing_vote > 0 THEN
                RAISE EXCEPTION 'Benutzer % hat bereits für Umfrage % abgestimmt', p_user_name, p_poll_id;
            END IF;
        ELSE
            -- Multiple Voting: Prüfe ob der Benutzer bereits für diese spezifische Option abgestimmt hat
            SELECT COUNT(*) INTO existing_option_vote 
            FROM user_votes 
            WHERE poll_id = p_poll_id AND option_id = p_option_id AND (user_id = user_uuid OR voter_name = p_user_name);
            
            IF existing_option_vote > 0 THEN
                RAISE EXCEPTION 'Benutzer % hat bereits für Option % abgestimmt', p_user_name, p_option_id;
            END IF;
        END IF;
        
        -- Erstelle Abstimmungseintrag
        INSERT INTO user_votes (poll_id, option_id, user_id, voter_name, is_anonymous)
        VALUES (p_poll_id, p_option_id, user_uuid, p_user_name, FALSE);
    ELSE
        -- Für anonyme Abstimmungen (erlaubt immer mehrfach, da kein User-Tracking)
        INSERT INTO user_votes (poll_id, option_id, is_anonymous)
        VALUES (p_poll_id, p_option_id, TRUE);
    END IF;
    
    -- Erhöhe Stimmenzahl
    UPDATE poll_options SET votes = votes + 1 WHERE id = p_option_id;
END;
$$ LANGUAGE plpgsql;

-- RLS (Row Level Security) Richtlinien - Für Entwicklung deaktiviert
-- ALTER TABLE polls ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE poll_options ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE user_votes ENABLE ROW LEVEL SECURITY;

-- Vereinfachte Richtlinien für Entwicklung (alle Operationen erlaubt)
-- Für Produktion sollten diese aktiviert und angepasst werden

-- Indizes für bessere Performance
CREATE INDEX IF NOT EXISTS idx_polls_created_at ON polls(created_at);
CREATE INDEX IF NOT EXISTS idx_poll_options_poll_id ON poll_options(poll_id);
CREATE INDEX IF NOT EXISTS idx_user_votes_poll_id ON user_votes(poll_id);
CREATE INDEX IF NOT EXISTS idx_user_votes_user_id ON user_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_user_votes_voter_name ON user_votes(voter_name);
CREATE INDEX IF NOT EXISTS idx_users_name ON users(name);
CREATE INDEX IF NOT EXISTS idx_polls_created_by ON polls(created_by);

-- Trigger für updated_at Spalte
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Erstelle Trigger nur wenn er nicht bereits existiert
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_polls_updated_at') THEN
        CREATE TRIGGER update_polls_updated_at 
            BEFORE UPDATE ON polls 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- Beispieldaten für die Entwicklung
-- Beispiel-Benutzer erstellen (nur wenn sie noch nicht existieren)
INSERT INTO users (name) VALUES 
    ('Max Mustermann'),
    ('Anna Schmidt'),
    ('Tom Entwickler')
ON CONFLICT (name) DO NOTHING;

-- Beispiel-Polls erstellen (nur wenn sie noch nicht existieren)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM polls WHERE title = 'Lieblings-Programmiersprache') THEN
        INSERT INTO polls (title, description, is_anonymous, created_by_name, is_active) VALUES 
            ('Lieblings-Programmiersprache', 'Welche ist deine bevorzugte Programmiersprache?', true, null, true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM polls WHERE title = 'Bestes Framework für Web-Entwicklung') THEN
        INSERT INTO polls (title, description, is_anonymous, created_by_name, is_active) VALUES 
            ('Bestes Framework für Web-Entwicklung', 'Welches Framework verwendest du am liebsten?', false, 'Max Mustermann', true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM polls WHERE title = 'Arbeitsplatz-Präferenz') THEN
        INSERT INTO polls (title, description, is_anonymous, created_by_name, is_active) VALUES 
            ('Arbeitsplatz-Präferenz', 'Wo arbeitest du am liebsten?', true, null, true);
    END IF;
END $$;

-- Beispiel-Poll-Optionen erstellen (nur wenn sie noch nicht existieren)
DO $$
DECLARE
    poll1_id INTEGER;
    poll2_id INTEGER;
    poll3_id INTEGER;
    allows_multiple_exists BOOLEAN := FALSE;
BEGIN
    -- Prüfe ob allows_multiple_votes Spalte existiert
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'polls' AND column_name = 'allows_multiple_votes'
    ) INTO allows_multiple_exists;
    
    -- Hole Poll IDs
    SELECT id INTO poll1_id FROM polls WHERE title = 'Lieblings-Programmiersprache' LIMIT 1;
    SELECT id INTO poll2_id FROM polls WHERE title = 'Bestes Framework für Web-Entwicklung' LIMIT 1;
    SELECT id INTO poll3_id FROM polls WHERE title = 'Arbeitsplatz-Präferenz' LIMIT 1;
    
    -- Optionen für die erste Umfrage (Single Voting)
    IF poll1_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM poll_options WHERE poll_id = poll1_id AND text = 'Python') THEN
        INSERT INTO poll_options (poll_id, text, votes) VALUES 
            (poll1_id, 'Python', 15),
            (poll1_id, 'JavaScript', 23),
            (poll1_id, 'Dart', 8),
            (poll1_id, 'Rust', 12);
    END IF;
    
    -- Optionen für die zweite Umfrage (Multiple Voting)
    IF poll2_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM poll_options WHERE poll_id = poll2_id AND text = 'React') THEN
        INSERT INTO poll_options (poll_id, text, votes) VALUES 
            (poll2_id, 'React', 18),
            (poll2_id, 'Flutter', 14),
            (poll2_id, 'Vue.js', 9),
            (poll2_id, 'Angular', 7);
        
        -- Setze Multiple Voting für zweite Umfrage (nur wenn Spalte existiert)
        IF allows_multiple_exists THEN
            UPDATE polls SET allows_multiple_votes = TRUE WHERE id = poll2_id;
        END IF;
    END IF;
    
    -- Optionen für die dritte Umfrage
    IF poll3_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM poll_options WHERE poll_id = poll3_id AND text = 'Home Office') THEN
        INSERT INTO poll_options (poll_id, text, votes) VALUES 
            (poll3_id, 'Home Office', 32),
            (poll3_id, 'Büro', 18),
            (poll3_id, 'Coworking Space', 5),
            (poll3_id, 'Café', 3);
    END IF;
END $$;