CREATE TABLE group_languages (
    group_id INT REFERENCES groups(id) ON DELETE CASCADE,
    language_id INT REFERENCES languages(id) ON DELETE CASCADE,
    PRIMARY KEY (group_id, language_id)
);
