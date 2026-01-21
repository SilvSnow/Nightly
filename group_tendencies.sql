-- Group Tendencies: Aggregate user attributes into group-level stats
-- Run after setup_matching.sql

-- ============================================
-- 1. ADD USERS TABLE (if not exists)
-- ============================================

CREATE EXTENSION IF NOT EXISTS citext;

CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    name                  TEXT        NOT NULL,
    email                 CITEXT      UNIQUE NOT NULL,
    age                   INT         CHECK (age >= 13),
    gender                INT         CHECK (gender IN (1,2,3,4)), -- 1=female, 2=male, 3=nonbinary, 4=prefer not to say
    profile_picture_url   TEXT,
    password_hash         TEXT,
    phone_number          TEXT,
    drinking_level        INT         CHECK (drinking_level IS NULL OR (drinking_level BETWEEN 0 AND 10)),
    smoking_level         INT         CHECK (smoking_level  IS NULL OR (smoking_level  BETWEEN 0 AND 10)),
    weed_level            INT         CHECK (weed_level     IS NULL OR (weed_level     BETWEEN 0 AND 10)),
    is_verified           BOOLEAN     DEFAULT FALSE,
    created_at            TIMESTAMPTZ DEFAULT now(),
    deleted_at            TIMESTAMPTZ
);

-- ============================================
-- 2. GROUP MEMBERSHIPS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS group_memberships (
    group_id BIGINT REFERENCES groups(id) ON DELETE CASCADE,
    user_id  BIGINT REFERENCES users(id) ON DELETE CASCADE,
    PRIMARY KEY (group_id, user_id)
);

-- ============================================
-- 3. VIEW: GROUP TENDENCIES FROM USERS
-- ============================================

CREATE OR REPLACE VIEW group_tendencies AS
SELECT
    gm.group_id,

    -- Group size
    COUNT(*) as num_people,

    -- Gender breakdown
    COUNT(*) FILTER (WHERE u.gender = 1) as num_women,
    COUNT(*) FILTER (WHERE u.gender = 2) as num_men,
    COUNT(*) FILTER (WHERE u.gender = 3) as num_nonbinary,

    -- Age range (formatted as "min-max")
    MIN(u.age) as min_age,
    MAX(u.age) as max_age,
    CONCAT(MIN(u.age), '-', MAX(u.age)) as age_range,
    ROUND(AVG(u.age), 1) as avg_age,

    -- Lifestyle averages (rounded to nearest integer for matching)
    ROUND(AVG(u.drinking_level)) as drinking_level,
    ROUND(AVG(u.smoking_level)) as smoking_level,
    ROUND(AVG(u.weed_level)) as weed_level,

    -- Lifestyle spread (high spread = diverse group)
    ROUND(STDDEV(u.drinking_level)::numeric, 1) as drinking_spread,
    ROUND(STDDEV(u.smoking_level)::numeric, 1) as smoking_spread,
    ROUND(STDDEV(u.weed_level)::numeric, 1) as weed_spread

FROM group_memberships gm
JOIN users u ON u.id = gm.user_id
WHERE u.deleted_at IS NULL
GROUP BY gm.group_id;

-- ============================================
-- 4. FUNCTION: UPDATE GROUP FROM TENDENCIES
-- ============================================

CREATE OR REPLACE FUNCTION sync_group_from_users(p_group_id BIGINT)
RETURNS VOID AS $$
BEGIN
    UPDATE groups g
    SET
        num_people = gt.num_people,
        age_range = gt.age_range,
        smoking_level = COALESCE(gt.smoking_level, g.smoking_level),
        drinking_level = COALESCE(gt.drinking_level, g.drinking_level),
        weed_level = COALESCE(gt.weed_level, g.weed_level)
    FROM group_tendencies gt
    WHERE g.id = p_group_id AND gt.group_id = p_group_id;
END;
$$ LANGUAGE plpgsql;

-- Sync all groups at once
CREATE OR REPLACE FUNCTION sync_all_groups_from_users()
RETURNS INT AS $$
DECLARE
    updated_count INT;
BEGIN
    UPDATE groups g
    SET
        num_people = gt.num_people,
        age_range = gt.age_range,
        smoking_level = COALESCE(gt.smoking_level, g.smoking_level),
        drinking_level = COALESCE(gt.drinking_level, g.drinking_level),
        weed_level = COALESCE(gt.weed_level, g.weed_level)
    FROM group_tendencies gt
    WHERE g.id = gt.group_id;

    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. TRIGGER: AUTO-UPDATE GROUP ON MEMBERSHIP CHANGE
-- ============================================

CREATE OR REPLACE FUNCTION trigger_sync_group()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM sync_group_from_users(OLD.group_id);
        RETURN OLD;
    ELSE
        PERFORM sync_group_from_users(NEW.group_id);
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_group_on_membership ON group_memberships;
CREATE TRIGGER trg_sync_group_on_membership
AFTER INSERT OR UPDATE OR DELETE ON group_memberships
FOR EACH ROW EXECUTE FUNCTION trigger_sync_group();

-- ============================================
-- 6. SAMPLE DATA FOR TESTING
-- ============================================

-- Insert sample users (if not exists)
INSERT INTO users (id, name, email, age, gender, drinking_level, smoking_level, weed_level)
VALUES
    (1, 'Alice', 'alice@test.com', 22, 1, 6, 2, 4),
    (2, 'Bob', 'bob@test.com', 24, 2, 7, 3, 5),
    (3, 'Charlie', 'charlie@test.com', 21, 2, 8, 1, 6),
    (4, 'Diana', 'diana@test.com', 23, 1, 5, 2, 3),
    (5, 'Eve', 'eve@test.com', 25, 1, 7, 4, 5),
    (6, 'Frank', 'frank@test.com', 22, 2, 6, 2, 4),
    (7, 'Grace', 'grace@test.com', 20, 1, 4, 1, 2),
    (8, 'Henry', 'henry@test.com', 26, 2, 8, 5, 7)
ON CONFLICT (id) DO UPDATE SET
    age = EXCLUDED.age,
    gender = EXCLUDED.gender,
    drinking_level = EXCLUDED.drinking_level,
    smoking_level = EXCLUDED.smoking_level,
    weed_level = EXCLUDED.weed_level;

-- Assign users to groups (Montreal groups 1, 8, 9, 10)
INSERT INTO group_memberships (group_id, user_id)
VALUES
    -- Group 1: Alice, Bob, Charlie, Diana (4 people)
    (1, 1), (1, 2), (1, 3), (1, 4),
    -- Group 8: Eve, Frank, Grace (3 people)
    (8, 5), (8, 6), (8, 7),
    -- Group 9: Alice, Eve, Grace, Henry (4 people - some overlap)
    (9, 1), (9, 5), (9, 7), (9, 8)
ON CONFLICT DO NOTHING;

-- Sync groups from user data
SELECT sync_all_groups_from_users() as groups_updated;

-- ============================================
-- 7. EXAMPLE QUERIES
-- ============================================

-- View group tendencies
-- SELECT * FROM group_tendencies;

-- Compare group tendencies vs stored group values
-- SELECT
--     g.id,
--     g.age_range as stored_age_range,
--     gt.age_range as calculated_age_range,
--     g.drinking_level as stored_drinking,
--     gt.drinking_level as calculated_drinking
-- FROM groups g
-- LEFT JOIN group_tendencies gt ON g.id = gt.group_id
-- WHERE gt.group_id IS NOT NULL;

SELECT 'Group tendencies setup complete!' as status;
