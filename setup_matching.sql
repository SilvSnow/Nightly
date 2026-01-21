-- Nightly Matching System - PostgreSQL Setup
-- Run with: psql -h localhost -U postgres -d postgres -W -f setup_matching.sql

-- ============================================
-- 1. DROP EXISTING TABLES (in dependency order)
-- ============================================
DROP TABLE IF EXISTS group_languages CASCADE;
DROP TABLE IF EXISTS group_memberships CASCADE;
DROP TABLE IF EXISTS groups CASCADE;
DROP TABLE IF EXISTS languages CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================
-- 2. CREATE TABLES
-- ============================================

CREATE EXTENSION IF NOT EXISTS citext;

-- Languages table
CREATE TABLE languages (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

-- Groups table with location radius matching
CREATE TABLE groups (
    id BIGSERIAL PRIMARY KEY,
    age_range TEXT,
    num_people INT,
    gender_group INT,
    target_lat DECIMAL(9,6),
    target_lon DECIMAL(9,6),
    travel_radius_km DECIMAL(5,1),
    smoking_level INT,
    drinking_level INT,
    weed_level INT,
    ideal_group_size INT,
    ideal_activity TEXT,
    sexuality_inclusive BOOLEAN,
    accessibility_friendly BOOLEAN,
    special_selections INT,
    group_rating NUMERIC(2,1),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Group languages junction table
CREATE TABLE group_languages (
    group_id BIGINT REFERENCES groups(id) ON DELETE CASCADE,
    language_id INT REFERENCES languages(id) ON DELETE CASCADE,
    PRIMARY KEY (group_id, language_id)
);

-- ============================================
-- 3. LOAD DATA FROM CSVs
-- ============================================

-- Create temp table to import CSV with all columns
CREATE TEMP TABLE groups_import (
    id INT,
    age_range TEXT,
    num_people INT,
    gender_group INT,
    target_lat DECIMAL(9,6),
    target_lon DECIMAL(9,6),
    travel_radius_km DECIMAL(5,1),
    smoking_level INT,
    drinking_level INT,
    weed_level INT,
    ideal_group_size INT,
    languages_text TEXT,  -- This column exists in CSV but we ignore it
    sexuality_inclusive TEXT,
    accessibility_friendly TEXT,
    special_selections INT,
    group_rating NUMERIC(2,1),
    ideal_activity TEXT,
    created_at TEXT
);

\copy languages(id, name) FROM './languages.csv' WITH CSV HEADER;
\copy groups_import FROM './groups.csv' WITH CSV HEADER;

-- Insert into groups, converting boolean text to actual boolean
INSERT INTO groups (id, age_range, num_people, gender_group, target_lat, target_lon,
    travel_radius_km, smoking_level, drinking_level, weed_level, ideal_group_size,
    ideal_activity, sexuality_inclusive, accessibility_friendly, special_selections,
    group_rating, created_at)
SELECT
    id, age_range, num_people, gender_group, target_lat, target_lon,
    travel_radius_km, smoking_level, drinking_level, weed_level, ideal_group_size,
    ideal_activity,
    sexuality_inclusive = 't',
    accessibility_friendly = 't',
    special_selections,
    group_rating,
    created_at::TIMESTAMPTZ
FROM groups_import;

DROP TABLE groups_import;

\copy group_languages(group_id, language_id) FROM './group_languages.csv' WITH CSV HEADER;

-- Reset sequences
SELECT setval('languages_id_seq', (SELECT MAX(id) FROM languages));
SELECT setval('groups_id_seq', (SELECT MAX(id) FROM groups));

-- ============================================
-- 4. MATCHING FUNCTIONS
-- ============================================

-- Haversine distance function (returns km)
CREATE OR REPLACE FUNCTION haversine(lat1 FLOAT, lon1 FLOAT, lat2 FLOAT, lon2 FLOAT)
RETURNS FLOAT AS $$
DECLARE
    R FLOAT := 6371;  -- Earth radius in km
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
    combined_radius := radius1 + radius2;

    -- Hard cutoff at 1.5x combined radius
    IF distance >= 1.5 * combined_radius THEN
        RETURN NULL;
    END IF;

    ratio := distance / NULLIF(combined_radius, 0);

    IF ratio <= 1.0 THEN
        -- Circles overlap: linear from 1.0 to 0.8
        RETURN 1.0 - 0.2 * ratio;
    ELSE
        -- Beyond combined radius: exponential decay
        overshoot := (ratio - 1.0) / 0.5;
        RETURN 0.8 * EXP(-4 * overshoot);
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Age overlap score with gap penalty
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
    -- Parse age ranges
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
        -- Bonus for strong overlap
        IF overlap_ratio >= 0.5 THEN
            base_score := LEAST(1.0, base_score + 0.1 * ((overlap_ratio - 0.5) / 0.5)^2);
        END IF;
        RETURN base_score;
    ELSE
        -- No overlap - exponential decay based on gap
        RETURN 0.5 * EXP(-gap / 3.0);
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Lifestyle score (squared difference)
CREATE OR REPLACE FUNCTION lifestyle_score(
    smoke_a INT, drink_a INT, weed_a INT,
    smoke_b INT, drink_b INT, weed_b INT
) RETURNS FLOAT AS $$
DECLARE
    smoke_sim FLOAT;
    drink_sim FLOAT;
    weed_sim FLOAT;
BEGIN
    smoke_sim := 1.0 - ((COALESCE(smoke_a,0) - COALESCE(smoke_b,0))^2 / 81.0);
    drink_sim := 1.0 - ((COALESCE(drink_a,0) - COALESCE(drink_b,0))^2 / 81.0);
    weed_sim := 1.0 - ((COALESCE(weed_a,0) - COALESCE(weed_b,0))^2 / 81.0);
    RETURN (GREATEST(0, smoke_sim) + GREATEST(0, drink_sim) + GREATEST(0, weed_sim)) / 3.0;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Size compatibility score
CREATE OR REPLACE FUNCTION size_score(size_a INT, size_b INT, ideal_a INT, ideal_b INT)
RETURNS FLOAT AS $$
DECLARE
    fit_a FLOAT;
    fit_b FLOAT;
BEGIN
    IF COALESCE(ideal_a, 0) = 0 THEN fit_a := 1.0;
    ELSE fit_a := GREATEST(0, 1.0 - ((ideal_a - size_b)^2::FLOAT / (ideal_a^2)));
    END IF;

    IF COALESCE(ideal_b, 0) = 0 THEN fit_b := 1.0;
    ELSE fit_b := GREATEST(0, 1.0 - ((ideal_b - size_a)^2::FLOAT / (ideal_b^2)));
    END IF;

    RETURN (fit_a + fit_b) / 2.0;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Threshold penalty function
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
-- 5. MAIN MATCHING VIEW
-- ============================================

CREATE OR REPLACE VIEW match_scores AS
WITH language_sets AS (
    SELECT
        group_id,
        ARRAY_AGG(language_id ORDER BY language_id) as lang_ids
    FROM group_languages
    GROUP BY group_id
),
pair_scores AS (
    SELECT
        g1.id as group_a,
        g2.id as group_b,

        -- Distance
        haversine(g1.target_lat, g1.target_lon, g2.target_lat, g2.target_lon) as distance_km,
        g1.travel_radius_km + g2.travel_radius_km as combined_radius_km,

        -- Sub-scores
        location_score(g1.target_lat, g1.target_lon, g1.travel_radius_km,
                      g2.target_lat, g2.target_lon, g2.travel_radius_km) as loc_score,
        age_score(g1.age_range, g2.age_range) as age_sc,
        lifestyle_score(g1.smoking_level, g1.drinking_level, g1.weed_level,
                       g2.smoking_level, g2.drinking_level, g2.weed_level) as lifestyle_sc,
        size_score(g1.num_people, g2.num_people, g1.ideal_group_size, g2.ideal_group_size) as size_sc,

        -- Activity similarity (simple match for now)
        CASE WHEN g1.ideal_activity = g2.ideal_activity THEN 1.0 ELSE 0.6 END as activity_sc,

        -- Language overlap (Jaccard-based)
        CASE
            WHEN l1.lang_ids = l2.lang_ids THEN 1.0
            WHEN ARRAY_LENGTH(ARRAY(SELECT UNNEST(l1.lang_ids) INTERSECT SELECT UNNEST(l2.lang_ids)), 1) > 0 THEN
                0.4 + 0.6 * SQRT(
                    ARRAY_LENGTH(ARRAY(SELECT UNNEST(l1.lang_ids) INTERSECT SELECT UNNEST(l2.lang_ids)), 1)::FLOAT /
                    ARRAY_LENGTH(ARRAY(SELECT UNNEST(l1.lang_ids) UNION SELECT UNNEST(l2.lang_ids)), 1)
                )
            ELSE 0.05
        END as lang_sc,

        -- Badge match
        CASE WHEN g1.sexuality_inclusive = g2.sexuality_inclusive THEN 1.0 ELSE 0.0 END as badge_sc

    FROM groups g1
    CROSS JOIN groups g2
    LEFT JOIN language_sets l1 ON l1.group_id = g1.id
    LEFT JOIN language_sets l2 ON l2.group_id = g2.id
    WHERE g1.id < g2.id
)
SELECT
    group_a,
    group_b,
    ROUND(distance_km::NUMERIC, 1) as distance_km,
    ROUND(combined_radius_km::NUMERIC, 1) as combined_radius_km,
    ROUND(loc_score::NUMERIC, 3) as location_score,
    ROUND(age_sc::NUMERIC, 3) as age_score,
    ROUND(lifestyle_sc::NUMERIC, 3) as lifestyle_score,
    ROUND(size_sc::NUMERIC, 3) as size_score,
    ROUND(activity_sc::NUMERIC, 3) as activity_score,
    ROUND(lang_sc::NUMERIC, 3) as lang_score,
    ROUND(badge_sc::NUMERIC, 3) as badge_score,
    ROUND(threshold_penalty(age_sc, lifestyle_sc, size_sc, activity_sc)::NUMERIC, 3) as penalty,

    -- Final weighted score
    ROUND((
        (0.10 * COALESCE(loc_score, 0) +
         0.15 * age_sc +
         0.15 * lifestyle_sc +
         0.15 * size_sc +
         0.20 * activity_sc +
         0.10 * lang_sc +
         0.10 * badge_sc +
         0.05 * 1.0)  -- rating placeholder
        * threshold_penalty(age_sc, lifestyle_sc, size_sc, activity_sc)
        * 100
    )::NUMERIC, 1) as match_score

FROM pair_scores
WHERE loc_score IS NOT NULL  -- Filter out pairs beyond max distance
ORDER BY match_score DESC;

-- ============================================
-- 6. HELPER QUERIES
-- ============================================

-- Show all matches
-- SELECT * FROM match_scores;

-- Top matches for a specific group
-- SELECT * FROM match_scores WHERE group_a = 1 OR group_b = 1 ORDER BY match_score DESC;

-- Montreal area groups only (groups with target near Montreal)
-- SELECT * FROM match_scores
-- WHERE group_a IN (SELECT id FROM groups WHERE target_lat BETWEEN 45.4 AND 45.7)
--   AND group_b IN (SELECT id FROM groups WHERE target_lat BETWEEN 45.4 AND 45.7);

SELECT 'Setup complete! Run: SELECT * FROM match_scores;' as status;
