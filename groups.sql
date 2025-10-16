
CREATE TABLE groups (
    id BIGSERIAL PRIMARY KEY,
    age_range TEXT,                        -- e.g. '19-24'
    num_people INT DEFAULT 1,
    gender_group INT,
    location_id INT REFERENCES locations(id), -- Since we'll be changing the specificity of locations, I think we should represent locations with ids
    smoking_level BOOLEAN,
    drinking_level BOOLEAN,
    weed_level BOOLEAN,
    ideal_group_size INT,
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
