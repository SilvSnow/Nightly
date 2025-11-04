CREATE TABLE languages (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

INSERT INTO languages (name) VALUES
('English'),
('French'),
('Mandarin');
