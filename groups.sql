
-- Step 2: Groups (your simplified version)
CREATE TABLE groups (
    id BIGSERIAL PRIMARY KEY,
    age_range TEXT,                        -- e.g. '19-24'
    num_men INT DEFAULT 0,
    num_women INT DEFAULT 0,
    num_nonbinary INT DEFAULT 0,
    location TEXT,
    smoking_level INT CHECK (smoking_level BETWEEN 1 AND 10),
    drinking_level INT CHECK (drinking_level BETWEEN 1 AND 10),
    weed_level INT CHECK (weed_level BETWEEN 1 AND 10),
    ideal_group_size INT,
    languages TEXT[],
    sexuality_inclusive BOOLEAN,
    accessibility_friendly BOOLEAN,
    group_rating NUMERIC(2,1),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Step 3: Memberships (links users to groups)
CREATE TABLE group_memberships (
    group_id BIGINT REFERENCES groups(id) ON DELETE CASCADE,
    user_id  BIGINT REFERENCES users(id) ON DELETE CASCADE,
    PRIMARY KEY (group_id, user_id)
);
