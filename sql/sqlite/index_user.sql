CREATE TABLE index_user_on_name (
  name TEXT NOT NULL,
  id BINARY(16) NOT NULL UNIQUE,
  PRIMARY KEY (name, id)
);

