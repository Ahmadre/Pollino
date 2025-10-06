-- Tabelle für Umfragen
CREATE TABLE IF NOT EXISTS polls (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- Tabelle für Umfrageoptionen
CREATE TABLE IF NOT EXISTS poll_options (
    id BIGSERIAL PRIMARY KEY,
    poll_id BIGINT NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    votes INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabelle für Benutzerabstimmungen (um Mehrfachabstimmungen zu verhindern)
CREATE TABLE IF NOT EXISTS user_votes (
    id BIGSERIAL PRIMARY KEY,
    poll_id BIGINT NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    option_id BIGINT NOT NULL REFERENCES poll_options(id) ON DELETE CASCADE,
    user_id UUID NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Eindeutige Constraint: Ein Benutzer kann nur einmal pro Umfrage abstimmen
    UNIQUE(poll_id, user_id)
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

-- Trigger für updated_at Spalte
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_polls_updated_at 
    BEFORE UPDATE ON polls 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Beispieldaten für die Entwicklung
INSERT INTO polls (title, description, is_active) VALUES 
    ('Lieblings-Programmiersprache', 'Welche ist deine bevorzugte Programmiersprache?', true),
    ('Bestes Framework für Web-Entwicklung', 'Welches Framework verwendest du am liebsten?', true),
    ('Arbeitsplatz-Präferenz', 'Wo arbeitest du am liebsten?', true);

-- Optionen für die erste Umfrage
INSERT INTO poll_options (poll_id, text, votes) VALUES 
    (1, 'Python', 15),
    (1, 'JavaScript', 23),
    (1, 'Dart', 8),
    (1, 'Rust', 12);

-- Optionen für die zweite Umfrage  
INSERT INTO poll_options (poll_id, text, votes) VALUES 
    (2, 'React', 18),
    (2, 'Flutter', 14),
    (2, 'Vue.js', 9),
    (2, 'Angular', 7);

-- Optionen für die dritte Umfrage
INSERT INTO poll_options (poll_id, text, votes) VALUES 
    (3, 'Home Office', 32),
    (3, 'Büro', 18),
    (3, 'Coworking Space', 5),
    (3, 'Café', 3);