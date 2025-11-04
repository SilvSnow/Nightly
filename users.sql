-- Enable once per database (for case-insensitive emails)
CREATE EXTENSION IF NOT EXISTS citext;

-- Table for user accounts
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name                  TEXT        NOT NULL,
    email                 CITEXT      UNIQUE NOT NULL,   -- case-insensitive unique
    age                   INT         CHECK (age >= 13), -- adjust min age as needed
    gender                INT         CHECK (gender IN (1,2,3,4)), -- 1=female, 2=male, 3=nonbinary, 4=prefer not to say
    profile_picture_url   TEXT,
    password_hash         TEXT,       -- or store OAuth provider IDs instead
    phone_number          TEXT,
    drinking_level        INT         CHECK (drinking_level IS NULL OR (drinking_level BETWEEN 1 AND 10)),
    smoking_level         INT         CHECK (smoking_level  IS NULL OR (smoking_level  BETWEEN 1 AND 10)),
    is_verified           BOOLEAN     DEFAULT FALSE,
    created_at            TIMESTAMPTZ DEFAULT now(),
    deleted_at            TIMESTAMPTZ
);

-- (Optional) If you want to ensure phone numbers are unique when present:
-- CREATE UNIQUE INDEX IF NOT EXISTS ux_users_phone
--   ON users ((NULLIF(phone_number, '')))
--   WHERE phone_number IS NOT NULL AND phone_number <> '';

INSERT INTO users (
  name, email, age, gender, profile_picture_url, password_hash, phone_number,
  drinking_level, smoking_level
)
VALUES
  ('Alice Johnson',          'alice@example.com',            21, 1, 'https://cdn.nightly.app/pics/alice.jpg',          'hash_pw_a', NULL,              6, 2),
  ('Ben Smith',              'ben@example.com',              23, 2, 'https://cdn.nightly.app/pics/ben.jpg',            'hash_pw_b', '+15551230001',    5, 1),
  ('Chloe Li',               'chloe@example.com',            20, 1, 'https://cdn.nightly.app/pics/chloe.jpg',          'hash_pw_c', NULL,              4, 1),
  ('David Kim',              'david.kim@example.com',        22, 2, 'https://cdn.nightly.app/pics/david.jpg',          'hash_pw_d', '+15551230002',    7, 2),
  ('Ella Martinez',          'ella.martinez@example.com',    24, 1, 'https://cdn.nightly.app/pics/ella.jpg',           'hash_pw_e', NULL,              6, 1),
  ('Farah Ahmed',            'farah.ahmed@example.com',      19, 1, 'https://cdn.nightly.app/pics/farah.jpg',          'hash_pw_f', '+15551230003',    3, 1),
  ('George Brown',           'george.brown@example.com',     25, 2, 'https://cdn.nightly.app/pics/george.jpg',         'hash_pw_g', NULL,              5, 2),
  ('Hannah Wang',            'hannah.wang@example.com',      21, 1, 'https://cdn.nightly.app/pics/hannah.jpg',         'hash_pw_h', '+15551230004',    4, 1),
  ('Ivan Petrov',            'ivan.petrov@example.com',      23, 2, 'https://cdn.nightly.app/pics/ivan.jpg',           'hash_pw_i', NULL,              6, 2),
  ('Jasmine Lee',            'jasmine.lee@example.com',      20, 1, 'https://cdn.nightly.app/pics/jasmine.jpg',        'hash_pw_j', '+15551230005',    5, 1),
  ('Kevin O''Connor',        'kevin.oconnor@example.com',    22, 2, 'https://cdn.nightly.app/pics/kevin.jpg',          'hash_pw_k', NULL,              5, 1),
  ('Lina Rossi',             'lina.rossi@example.com',       24, 1, 'https://cdn.nightly.app/pics/lina.jpg',           'hash_pw_l', '+15551230006',    6, 1),
  ('Mohammed Ali',           'mohammed.ali@example.com',     26, 2, 'https://cdn.nightly.app/pics/mohammed.jpg',       'hash_pw_m', NULL,              5, 2),
  ('Nina Patel',             'nina.patel@example.com',       22, 1, 'https://cdn.nightly.app/pics/nina.jpg',           'hash_pw_n', '+15551230007',    4, 1),
  ('Oscar Diaz',             'oscar.diaz@example.com',       27, 2, 'https://cdn.nightly.app/pics/oscar.jpg',          'hash_pw_o', NULL,              6, 3),
  ('Priya Singh',            'priya.singh@example.com',      23, 1, 'https://cdn.nightly.app/pics/priya.jpg',          'hash_pw_p', '+15551230008',    3, 1),
  ('Quentin Zhao',           'quentin.zhao@example.com',     24, 2, 'https://cdn.nightly.app/pics/quentin.jpg',        'hash_pw_q', NULL,              5, 2),
  ('Riley Morgan',           'riley.morgan@example.com',     21, 3, 'https://cdn.nightly.app/pics/riley.jpg',          'hash_pw_r', '+15551230009',    4, 2),
  ('Sofia Novak',            'sofia.novak@example.com',      25, 1, 'https://cdn.nightly.app/pics/sofia.jpg',          'hash_pw_s', NULL,              6, 1),
  ('Tariq Hassan',           'tariq.hassan@example.com',     26, 2, 'https://cdn.nightly.app/pics/tariq.jpg',          'hash_pw_t', '+15551230010',    7, 3),
  ('Uma Rao',                'uma.rao@example.com',          20, 1, 'https://cdn.nightly.app/pics/uma.jpg',            'hash_pw_u', NULL,              2, 1),
  ('Valentine Brooks',       'val.brooks@example.com',       22, 4, 'https://cdn.nightly.app/pics/val.jpg',            'hash_pw_v', '+15551230011',    5, 1),
  ('Wendy Cho',              'wendy.cho@example.com',        23, 1, 'https://cdn.nightly.app/pics/wendy.jpg',          'hash_pw_w', NULL,              4, 1),
  ('Xavier Laurent',         'xavier.laurent@example.com',   24, 2, 'https://cdn.nightly.app/pics/xavier.jpg',         'hash_pw_x', '+15551230012',    6, 2),
  ('Yara Haddad',            'yara.haddad@example.com',      21, 1, 'https://cdn.nightly.app/pics/yara.jpg',           'hash_pw_y', NULL,              3, 1),
  ('Zane Miller',            'zane.miller@example.com',      23, 2, 'https://cdn.nightly.app/pics/zane.jpg',           'hash_pw_z', '+15551230013',    5, 2);
