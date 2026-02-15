-- Nightly Database Setup - Complete Schema for API
-- Run with: psql -h localhost -U postgres -d postgres -f setup_database.sql

-- ============================================
-- 1. EXTENSIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS citext;

-- ============================================
-- 2. DROP EXISTING TABLES (in dependency order)
-- ============================================
DROP TABLE IF EXISTS group_locations CASCADE;
DROP TABLE IF EXISTS group_likes CASCADE;
DROP TABLE IF EXISTS group_languages CASCADE;
DROP TABLE IF EXISTS group_memberships CASCADE;
DROP TABLE IF EXISTS groups CASCADE;
DROP TABLE IF EXISTS languages CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================
-- 3. CREATE TABLES
-- ============================================

-- Users table
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email CITEXT UNIQUE NOT NULL,
    age INT CHECK (age >= 18),
    gender INT CHECK (gender IN (1,2,3,4)),  -- 1=female, 2=male, 3=nonbinary, 4=prefer not to say
    profile_picture_url TEXT,
    password_hash TEXT,
    phone_number TEXT,
    drinking_level INT CHECK (drinking_level IS NULL OR (drinking_level BETWEEN 1 AND 10)),
    smoking_level INT CHECK (smoking_level IS NULL OR (smoking_level BETWEEN 1 AND 10)),
    weed_level INT CHECK (weed_level IS NULL OR (weed_level BETWEEN 1 AND 10)),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Languages table
CREATE TABLE languages (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

-- Insert common languages
INSERT INTO languages (name) VALUES
    ('English'), ('French'), ('Spanish'), ('Mandarin'), ('Arabic'),
    ('Portuguese'), ('Hindi'), ('Bengali'), ('Russian'), ('Japanese');

-- Groups table
CREATE TABLE groups (
    id BIGSERIAL PRIMARY KEY,
    age_range TEXT,
    num_people INT DEFAULT 1,
    num_men INT DEFAULT 0,
    num_women INT DEFAULT 0,
    num_nonbinary INT DEFAULT 0,
    gender_group INT,  -- 1=male, 2=female, 3=mixed
    target_lat DECIMAL(9,6),
    target_lon DECIMAL(9,6),
    travel_radius_km DECIMAL(5,1) DEFAULT 15,
    smoking_level INT,
    drinking_level INT,
    weed_level INT,
    ideal_group_size INT,
    ideal_activity TEXT,
    sexuality_inclusive BOOLEAN DEFAULT TRUE,
    accessibility_friendly BOOLEAN DEFAULT FALSE,
    special_selections INT,
    group_rating NUMERIC(2,1),
    active_until TIMESTAMPTZ,  -- When group is active until (NULL = not active)
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Group memberships
CREATE TABLE group_memberships (
    group_id BIGINT REFERENCES groups(id) ON DELETE CASCADE,
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (group_id, user_id)
);

-- Group languages
CREATE TABLE group_languages (
    group_id BIGINT REFERENCES groups(id) ON DELETE CASCADE,
    language_id INT REFERENCES languages(id) ON DELETE CASCADE,
    PRIMARY KEY (group_id, language_id)
);

-- Group likes (for matching)
CREATE TABLE group_likes (
    liker_id BIGINT REFERENCES groups(id) ON DELETE CASCADE,
    liked_id BIGINT REFERENCES groups(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (liker_id, liked_id)
);

-- Group locations (multi-location support)
CREATE TABLE group_locations (
    id BIGSERIAL PRIMARY KEY,
    group_id BIGINT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    label TEXT,
    target_lat DECIMAL(9,6) NOT NULL,
    target_lon DECIMAL(9,6) NOT NULL,
    travel_radius_km DECIMAL(5,1) DEFAULT 15,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_group_locations_group ON group_locations(group_id);

-- ============================================
-- 4. MATCHING FUNCTIONS
-- ============================================

-- Haversine distance (returns km)
CREATE OR REPLACE FUNCTION haversine(lat1 FLOAT, lon1 FLOAT, lat2 FLOAT, lon2 FLOAT)
RETURNS FLOAT AS $$
DECLARE
    R FLOAT := 6371;
    dlat FLOAT;
    dlon FLOAT;
    a FLOAT;
    c FLOAT;
BEGIN
    dlat := RADIANS(lat2 - lat1);
    dlon := RADIANS(lon2 - lon1);
    a := SIN(dlat/2)^2 + COS(RADIANS(lat1)) * COS(RADIANS(lat2)) * SIN(dlon/2)^2;
    c := 2 * ATAN2(SQRT(a), SQRT(1-a));
    RETURN R * c;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Location score based on radius intersection
CREATE OR REPLACE FUNCTION location_score(
    lat1 FLOAT, lon1 FLOAT, radius1 FLOAT,
    lat2 FLOAT, lon2 FLOAT, radius2 FLOAT
) RETURNS FLOAT AS $$
DECLARE
    distance FLOAT;
    combined_radius FLOAT;
    ratio FLOAT;
    overshoot FLOAT;
BEGIN
    distance := haversine(lat1, lon1, lat2, lon2);
    combined_radius := COALESCE(radius1, 15) + COALESCE(radius2, 15);

    IF distance >= 1.5 * combined_radius THEN
        RETURN NULL;
    END IF;

    ratio := distance / NULLIF(combined_radius, 0);

    IF ratio <= 1.0 THEN
        RETURN 1.0 - 0.2 * ratio;
    ELSE
        overshoot := (ratio - 1.0) / 0.5;
        RETURN 0.8 * EXP(-4 * overshoot);
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Best location score across multiple locations for two groups
CREATE OR REPLACE FUNCTION best_location_score(g1_id BIGINT, g2_id BIGINT)
RETURNS TABLE(best_score FLOAT, best_distance FLOAT) AS $$
    SELECT ls.score, ls.distance
    FROM group_locations l1
    CROSS JOIN group_locations l2
    CROSS JOIN LATERAL (
        SELECT
            location_score(l1.target_lat, l1.target_lon, l1.travel_radius_km,
                          l2.target_lat, l2.target_lon, l2.travel_radius_km) AS score,
            haversine(l1.target_lat, l1.target_lon, l2.target_lat, l2.target_lon) AS distance
    ) ls
    WHERE l1.group_id = g1_id
      AND l2.group_id = g2_id
      AND ls.score IS NOT NULL
    ORDER BY ls.score DESC
    LIMIT 1;
$$ LANGUAGE sql STABLE;

-- Age overlap score
CREATE OR REPLACE FUNCTION age_score(age_range_a TEXT, age_range_b TEXT)
RETURNS FLOAT AS $$
DECLARE
    a_min INT; a_max INT;
    b_min INT; b_max INT;
    overlap INT;
    gap INT;
    min_range INT;
    overlap_ratio FLOAT;
    base_score FLOAT;
BEGIN
    IF age_range_a IS NULL OR age_range_b IS NULL THEN
        RETURN 0.7;  -- Default score for missing data
    END IF;

    a_min := SPLIT_PART(age_range_a, '-', 1)::INT;
    a_max := SPLIT_PART(age_range_a, '-', 2)::INT;
    b_min := SPLIT_PART(age_range_b, '-', 1)::INT;
    b_max := SPLIT_PART(age_range_b, '-', 2)::INT;

    overlap := GREATEST(0, LEAST(a_max, b_max) - GREATEST(a_min, b_min));
    gap := GREATEST(0, GREATEST(a_min, b_min) - LEAST(a_max, b_max));
    min_range := GREATEST(1, LEAST(a_max - a_min, b_max - b_min));

    IF overlap > 0 THEN
        overlap_ratio := overlap::FLOAT / min_range;
        base_score := 0.5 + 0.5 * LEAST(1.0, overlap_ratio);
        IF overlap_ratio >= 0.5 THEN
            base_score := LEAST(1.0, base_score + 0.1 * ((overlap_ratio - 0.5) / 0.5)^2);
        END IF;
        RETURN base_score;
    ELSE
        RETURN 0.5 * EXP(-gap / 3.0);
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Lifestyle score
CREATE OR REPLACE FUNCTION lifestyle_score(
    smoke_a INT, drink_a INT, weed_a INT,
    smoke_b INT, drink_b INT, weed_b INT
) RETURNS FLOAT AS $$
DECLARE
    smoke_sim FLOAT;
    drink_sim FLOAT;
    weed_sim FLOAT;
BEGIN
    smoke_sim := 1.0 - ((COALESCE(smoke_a,5) - COALESCE(smoke_b,5))^2 / 81.0);
    drink_sim := 1.0 - ((COALESCE(drink_a,5) - COALESCE(drink_b,5))^2 / 81.0);
    weed_sim := 1.0 - ((COALESCE(weed_a,5) - COALESCE(weed_b,5))^2 / 81.0);
    RETURN (GREATEST(0, smoke_sim) + GREATEST(0, drink_sim) + GREATEST(0, weed_sim)) / 3.0;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Size score
CREATE OR REPLACE FUNCTION size_score(size_a INT, size_b INT, ideal_a INT, ideal_b INT)
RETURNS FLOAT AS $$
DECLARE
    fit_a FLOAT;
    fit_b FLOAT;
BEGIN
    IF COALESCE(ideal_a, 0) = 0 THEN fit_a := 1.0;
    ELSE fit_a := GREATEST(0, 1.0 - ((ideal_a - COALESCE(size_b,1))^2::FLOAT / (ideal_a^2)));
    END IF;

    IF COALESCE(ideal_b, 0) = 0 THEN fit_b := 1.0;
    ELSE fit_b := GREATEST(0, 1.0 - ((ideal_b - COALESCE(size_a,1))^2::FLOAT / (ideal_b^2)));
    END IF;

    RETURN (fit_a + fit_b) / 2.0;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Threshold penalty
CREATE OR REPLACE FUNCTION threshold_penalty(
    age_sc FLOAT, lifestyle_sc FLOAT, size_sc FLOAT, activity_sc FLOAT
) RETURNS FLOAT AS $$
DECLARE
    penalty FLOAT := 1.0;
BEGIN
    IF age_sc < 0.3 THEN penalty := penalty * EXP(-3 * (0.3 - age_sc)); END IF;
    IF lifestyle_sc < 0.4 THEN penalty := penalty * EXP(-3 * (0.4 - lifestyle_sc)); END IF;
    IF size_sc < 0.5 THEN penalty := penalty * EXP(-3 * (0.5 - size_sc)); END IF;
    IF activity_sc < 0.4 THEN penalty := penalty * EXP(-3 * (0.4 - activity_sc)); END IF;
    RETURN penalty;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 5. MATCH SCORES VIEW
-- ============================================

CREATE OR REPLACE VIEW match_scores AS
WITH language_sets AS (
    SELECT
        group_id,
        ARRAY_AGG(language_id ORDER BY language_id) as lang_ids
    FROM group_languages
    GROUP BY group_id
),
groups_with_locations AS (
    SELECT DISTINCT group_id FROM group_locations
),
pair_scores AS (
    SELECT
        g1.id as group_a,
        g2.id as group_b,
        bls.best_distance as distance_km,
        bls.best_score as loc_score,
        age_score(g1.age_range, g2.age_range) as age_sc,
        lifestyle_score(g1.smoking_level, g1.drinking_level, g1.weed_level,
                       g2.smoking_level, g2.drinking_level, g2.weed_level) as lifestyle_sc,
        size_score(g1.num_people, g2.num_people, g1.ideal_group_size, g2.ideal_group_size) as size_sc,
        CASE WHEN LOWER(COALESCE(g1.ideal_activity,'')) = LOWER(COALESCE(g2.ideal_activity,'')) THEN 1.0 ELSE 0.6 END as activity_sc,
        CASE
            WHEN l1.lang_ids = l2.lang_ids THEN 1.0
            WHEN l1.lang_ids IS NULL OR l2.lang_ids IS NULL THEN 0.5
            WHEN ARRAY_LENGTH(ARRAY(SELECT UNNEST(l1.lang_ids) INTERSECT SELECT UNNEST(l2.lang_ids)), 1) > 0 THEN
                0.4 + 0.6 * SQRT(
                    ARRAY_LENGTH(ARRAY(SELECT UNNEST(l1.lang_ids) INTERSECT SELECT UNNEST(l2.lang_ids)), 1)::FLOAT /
                    ARRAY_LENGTH(ARRAY(SELECT UNNEST(l1.lang_ids) UNION SELECT UNNEST(l2.lang_ids)), 1)
                )
            ELSE 0.05
        END as lang_sc
    FROM groups g1
    JOIN groups_with_locations gl1 ON gl1.group_id = g1.id
    CROSS JOIN groups g2
    JOIN groups_with_locations gl2 ON gl2.group_id = g2.id
    CROSS JOIN LATERAL best_location_score(g1.id, g2.id) bls
    LEFT JOIN language_sets l1 ON l1.group_id = g1.id
    LEFT JOIN language_sets l2 ON l2.group_id = g2.id
    WHERE g1.id < g2.id
)
SELECT
    group_a,
    group_b,
    ROUND(distance_km::NUMERIC, 1) as distance_km,
    ROUND(loc_score::NUMERIC, 3) as location_score,
    ROUND(age_sc::NUMERIC, 3) as age_score,
    ROUND(lifestyle_sc::NUMERIC, 3) as lifestyle_score,
    ROUND(size_sc::NUMERIC, 3) as size_score,
    ROUND(activity_sc::NUMERIC, 3) as activity_score,
    ROUND(lang_sc::NUMERIC, 3) as lang_score,
    ROUND((
        (0.15 * COALESCE(loc_score, 0) +
         0.20 * age_sc +
         0.15 * lifestyle_sc +
         0.15 * size_sc +
         0.25 * activity_sc +
         0.10 * lang_sc)
        * threshold_penalty(age_sc, lifestyle_sc, size_sc, activity_sc)
        * 100
    )::NUMERIC, 1) as match_score
FROM pair_scores
WHERE loc_score IS NOT NULL
ORDER BY match_score DESC;

-- ============================================
-- 6. GROUP TENDENCIES VIEW
-- ============================================

CREATE OR REPLACE VIEW group_tendencies AS
SELECT
    g.id as group_id,
    COUNT(u.id)::INT as num_people,
    COUNT(CASE WHEN u.gender = 1 THEN 1 END)::INT as num_women,
    COUNT(CASE WHEN u.gender = 2 THEN 1 END)::INT as num_men,
    COUNT(CASE WHEN u.gender = 3 THEN 1 END)::INT as num_nonbinary,
    CONCAT(MIN(u.age), '-', MAX(u.age)) as age_range,
    ROUND(AVG(u.age)::NUMERIC, 1) as avg_age,
    ROUND(AVG(u.drinking_level)::NUMERIC, 0)::INT as drinking_level,
    ROUND(AVG(u.smoking_level)::NUMERIC, 0)::INT as smoking_level,
    ROUND(AVG(u.weed_level)::NUMERIC, 0)::INT as weed_level
FROM groups g
LEFT JOIN group_memberships gm ON g.id = gm.group_id
LEFT JOIN users u ON gm.user_id = u.id
GROUP BY g.id;

-- ============================================
-- 7. SYNC FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION sync_group_from_users(target_group_id BIGINT)
RETURNS VOID AS $$
BEGIN
    UPDATE groups g SET
        num_people = t.num_people,
        num_men = t.num_men,
        num_women = t.num_women,
        num_nonbinary = t.num_nonbinary,
        age_range = t.age_range,
        drinking_level = t.drinking_level,
        smoking_level = t.smoking_level,
        weed_level = t.weed_level
    FROM group_tendencies t
    WHERE g.id = target_group_id AND t.group_id = target_group_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_groups_active ON groups(active_until) WHERE active_until IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_group_memberships_user ON group_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_group_likes_liked ON group_likes(liked_id);

-- ============================================
-- Done!
-- ============================================
SELECT 'Database setup complete!' as status;
