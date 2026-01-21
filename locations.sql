CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    latitude DECIMAL(9,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL
);

INSERT INTO locations (name, latitude, longitude)
VALUES
    ('Montreal', 45.5017, -73.5673),
    ('Toronto', 43.6532, -79.3832),
    ('Vancouver', 49.2827, -123.1207),
    ('Calgary', 51.0447, -114.0719),
    ('Ottawa', 45.4215, -75.6972),
    ('Mississauga', 43.5890, -79.6441),
    ('Hamilton', 43.2557, -79.8711),
    ('Laval', 45.6066, -73.7124);
