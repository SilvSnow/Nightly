-- Step 2: Groups (your simplified version)
CREATE TABLE groups (
    id BIGSERIAL PRIMARY KEY,
    age_range TEXT,                        -- e.g. '19-24'
    num_men INT,
    num_women INT,
    num_nonbinary INT,
    num_people INT,
    gender_group INT,  -- 1 = male, 2 = female, 3 = mixed
    -- Location: where the group wants to go and how far they'll travel
    target_lat DECIMAL(9,6),               -- target area latitude
    target_lon DECIMAL(9,6),               -- target area longitude
    travel_radius_km DECIMAL(5,1),         -- how far willing to travel (km)
    smoking_level INT,
    drinking_level INT,
    weed_level INT, -- 0-10 (0-5 stars with half stars)
    ideal_group_size INT,
    ideal_activity TEXT, -- TODO change into a table, PCA of the acivity to allow general ones would be insane too.
    sexuality_inclusive BOOLEAN,
    accessibility_friendly BOOLEAN,
    special_selections INT, --from 1-4, using binary mapping wherer 1=men 2=mixed 3=women 4=none
    group_rating NUMERIC(2,1),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Step 3: Memberships (links users to groups)
CREATE TABLE group_memberships (
    group_id BIGINT REFERENCES groups(id) ON DELETE CASCADE,
    user_id  BIGINT REFERENCES users(id) ON DELETE CASCADE,
    PRIMARY KEY (group_id, user_id)
);
