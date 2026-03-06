ALTER TABLE users
  ADD COLUMN is_official BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN badge_type VARCHAR(32) NULL;

CREATE INDEX idx_users_is_official ON users (is_official);
