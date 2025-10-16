CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

INSERT INTO locations (name)
VALUES ('Montreal'), ('Toronto'), ('Vancouver'), ('Calgary');
