ALTER TABLE users
  ADD COLUMN is_online BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN last_active_at TIMESTAMP NULL;

CREATE INDEX idx_users_is_online ON users (is_online);
CREATE INDEX idx_users_last_active_at ON users (last_active_at);
