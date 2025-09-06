-- Table for user accounts
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email CITEXT UNIQUE NOT NULL,
    age INT CHECK (age >= 13), -- adjust min age as needed
    profile_picture_url TEXT,
    password_hash TEXT,         -- or SSO token if using OAuth
    phone_number TEXT,          -- optional
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Example: inserting some users
INSERT INTO users (name, email, age, profile_picture_url, password_hash, phone_number)
VALUES
  ('Alice Johnson', 'alice@example.com', 21, 'https://cdn.nightly.app/pics/alice.jpg', 'hashed_pw_123', NULL),
  ('Ben Smith', 'ben@example.com', 23, 'https://cdn.nightly.app/pics/ben.jpg', 'hashed_pw_456', '+15551234567'),
  ('Chloe Li', 'chloe@example.com', 20, 'https://cdn.nightly.app/pics/chloe.jpg', 'hashed_pw_789', NULL),
  ('David Kim', 'david.kim@example.com', 22, 'https://cdn.nightly.app/pics/david.jpg', 'hashed_pw_234', '+15559876543'),
  ('Ella Martinez', 'ella.martinez@example.com', 24, 'https://cdn.nightly.app/pics/ella.jpg', 'hashed_pw_345', NULL),
  ('Farah Ahmed', 'farah.ahmed@example.com', 19, 'https://cdn.nightly.app/pics/farah.jpg', 'hashed_pw_456', '+15551239876'),
  ('George Brown', 'george.brown@example.com', 25, 'https://cdn.nightly.app/pics/george.jpg', 'hashed_pw_567', NULL),
  ('Hannah Wang', 'hannah.wang@example.com', 21, 'https://cdn.nightly.app/pics/hannah.jpg', 'hashed_pw_678', '+15553456789'),
  ('Ivan Petrov', 'ivan.petrov@example.com', 23, 'https://cdn.nightly.app/pics/ivan.jpg', 'hashed_pw_789', NULL),
  ('Jasmine Lee', 'jasmine.lee@example.com', 20, 'https://cdn.nightly.app/pics/jasmine.jpg', 'hashed_pw_890', '+15557654321'),
  ('Kevin O''Connor', 'kevin.oconnor@example.com', 22, 'https://cdn.nightly.app/pics/kevin.jpg', 'hashed_pw_901', NULL),
  ('Lina Rossi', 'lina.rossi@example.com', 24, 'https://cdn.nightly.app/pics/lina.jpg', 'hashed_pw_012', '+15552349876'),
  ('Mohammed Ali', 'mohammed.ali@example.com', 26, 'https://cdn.nightly.app/pics/mohammed.jpg', 'hashed_pw_345', NULL);
