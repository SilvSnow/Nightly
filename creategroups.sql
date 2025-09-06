-- 1) Create four groups (minimal fields filled to satisfy checks)
WITH
g5 AS (
  INSERT INTO groups (
    age_range, num_men, num_women, num_nonbinary, location,
    smoking_level, drinking_level, weed_level,
    ideal_group_size, languages, sexuality_inclusive, accessibility_friendly, group_rating
  )
  VALUES ('19-24', 2, 3, 0, 'Montreal', 3, 6, 4, 6, ARRAY['English','French'], TRUE, TRUE, 4.3)
  RETURNING id
),
g4 AS (
  INSERT INTO groups (
    age_range, num_men, num_women, num_nonbinary, location,
    smoking_level, drinking_level, weed_level,
    ideal_group_size, languages, sexuality_inclusive, accessibility_friendly, group_rating
  )
  VALUES ('21-27', 2, 1, 1, 'Toronto', 2, 5, 3, 5, ARRAY['English'], FALSE, TRUE, 3.9)
  RETURNING id
),
g3 AS (
  INSERT INTO groups (
    age_range, num_men, num_women, num_nonbinary, location,
    smoking_level, drinking_level, weed_level,
    ideal_group_size, languages, sexuality_inclusive, accessibility_friendly, group_rating
  )
  VALUES ('20-25', 1, 2, 0, 'Vancouver', 4, 6, 7, 4, ARRAY['English','Mandarin'], TRUE, FALSE, 4.1)
  RETURNING id
),
g1 AS (
  INSERT INTO groups (
    age_range, num_men, num_women, num_nonbinary, location,
    smoking_level, drinking_level, weed_level,
    ideal_group_size, languages, sexuality_inclusive, accessibility_friendly, group_rating
  )
  VALUES ('22-28', 1, 0, 0, 'Calgary', 1, 3, 2, 2, ARRAY['English'], TRUE, TRUE, 4.0)
  RETURNING id
)

-- 2) Link users to the groups 
INSERT INTO group_memberships (group_id, user_id)
SELECT (SELECT id FROM g5), u.id FROM users u WHERE u.email IN
  ('alice@example.com','ben@example.com','chloe@example.com','david.kim@example.com','ella.martinez@example.com')
UNION ALL
SELECT (SELECT id FROM g4), u.id FROM users u WHERE u.email IN
  ('farah.ahmed@example.com','george.brown@example.com','hannah.wang@example.com','ivan.petrov@example.com')
UNION ALL
SELECT (SELECT id FROM g3), u.id FROM users u WHERE u.email IN
  ('jasmine.lee@example.com','kevin.oconnor@example.com','lina.rossi@example.com')
UNION ALL
SELECT (SELECT id FROM g1), u.id FROM users u WHERE u.email IN
  ('mohammed.ali@example.com');

-- 3) (Optional) Quick verification: group sizes + member names
SELECT
  gm.group_id,
  COUNT(*) AS member_count,
  ARRAY_AGG(u.name ORDER BY u.name) AS members
FROM group_memberships gm
JOIN users u ON u.id = gm.user_id
GROUP BY gm.group_id
ORDER BY member_count DESC, gm.group_id;
