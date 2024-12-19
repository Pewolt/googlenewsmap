-- Erstelle die Tabelle für Länder mit Standardisierung des ISO-Codes
CREATE TABLE countries (
    id SERIAL PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    iso_code VARCHAR(2) NOT NULL UNIQUE CHECK (iso_code = UPPER(iso_code))
);

-- Erstelle die Tabelle für Themen
CREATE TABLE topics (
    id SERIAL PRIMARY KEY,
    topic_name VARCHAR(100) NOT NULL UNIQUE
);

-- Erstelle die Tabelle für Feeds ohne ON DELETE CASCADE und mit zusätzlichen Indizes
CREATE TABLE feeds (
    id SERIAL PRIMARY KEY,
    title TEXT,
    link TEXT UNIQUE,
    language VARCHAR(5),
    last_build_date TIMESTAMP,
    country_id INTEGER NOT NULL REFERENCES countries(id),
    topic_id INTEGER NOT NULL REFERENCES topics(id)
);

-- Indexe für bessere Abfrageleistung auf feeds
CREATE INDEX idx_feeds_country_id ON feeds(country_id);
CREATE INDEX idx_feeds_topic_id ON feeds(topic_id);

-- Erstelle die Tabelle für Artikel mit UNIQUE-Constraint und TIMESTAMP WITH TIME ZONE
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    link TEXT NOT NULL,
    pub_date TIMESTAMP WITH TIME ZONE,
    publisher TEXT,
    feed_id INTEGER NOT NULL REFERENCES feeds(id),
    UNIQUE (link, feed_id)
);

-- Index für bessere Abfrageleistung auf articles
CREATE INDEX idx_articles_feed_id ON articles(feed_id);
