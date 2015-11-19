CREATE TABLE user (
    added_id INTEGER PRIMARY KEY,
    id BINARY(16) NOT NULL UNIQUE,
    created_at DATETIME,
    updated_at DATETIME,
    attributes TEXT
);

