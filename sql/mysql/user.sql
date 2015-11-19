CREATE TABLE user (
    added_id INT NOT NULL AUTO_INCREMENT,
    id BINARY(16) NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    attributes TEXT,
    PRIMARY KEY (added_id),
    UNIQUE KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

