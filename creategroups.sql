-- =====================================================
-- SIMPLE WORKING GROUP CREATION SCRIPT
-- =====================================================

-- (optional cleanup)
TRUNCATE groups RESTART IDENTITY CASCADE;

-- 1️⃣  Create five groups
INSERT INTO groups (
  age_range, num_people, gender_group,
  location,
  smoking_level, drinking_level, weed_level,
  ideal_group_size,
  languages,
  sexuality_inclusive, accessibility_friendly,
  special_selections,
  group_rating
)
VALUES
  ('19-24', 0, 3, 'Montreal',   2, 7, 5, 5, ARRAY['English','French'], TRUE,  TRUE,  2, 4.4),
  ('20-26', 0, 3, 'Toronto',    1, 5, 3, 6, ARRAY['English'],          TRUE,  TRUE,  4, 4.0),
  ('21-27', 0, 3, 'Vancouver',  4, 6, 7, 7, ARRAY['English','Mandarin'], TRUE, FALSE, 3, 4.2),
  ('22-28', 0, 3, 'Calgary',    0, 3, 2, 8, ARRAY['English'],          TRUE,  TRUE,  1, 3.9),
  ('19-25', 0, 3, 'Ottawa',     5, 2, 6, 9, ARRAY['English','French'], FALSE, TRUE,  2, 4.1);

-- 2️⃣  Grab the five new group IDs
WITH g AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS gidx
  FROM groups
  ORDER BY id DESC
  LIMIT 5
),
u AS (
  SELECT id AS user_id, ROW_NUMBER() OVER (ORDER BY random()) AS rn
  FROM users
  LIMIT 26
)
-- 3️⃣  Distribute 26 users into 5 groups
INSERT INTO group_memberships (group_id, user_id)
SELECT
  CASE
    WHEN rn BETWEEN  1 AND  4 THEN (SELECT id FROM g WHERE gidx = 1)
    WHEN rn BETWEEN  5 AND  8 THEN (SELECT id FROM g WHERE gidx = 2)
    WHEN rn BETWEEN  9 AND 13 THEN (SELECT id FROM g WHERE gidx = 3)
    WHEN rn BETWEEN 14 AND 19 THEN (SELECT id FROM g WHERE gidx = 4)
    WHEN rn BETWEEN 20 AND 26 THEN (SELECT id FROM g WHERE gidx = 5)
  END AS group_id,
  user_id
FROM u;

-- 4️⃣  Verify everything
SELECT
  g.id AS group_id,
  g.location,
  COUNT(gm.user_id) AS members,
  ARRAY_AGG(u.name ORDER BY u.name) AS member_names
FROM groups g
LEFT JOIN group_memberships gm ON g.id = gm.group_id
LEFT JOIN users u ON gm.user_id = u.id
GROUP BY g.id, g.location
ORDER BY g.id;
