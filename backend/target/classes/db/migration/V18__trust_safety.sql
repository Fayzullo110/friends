-- User privacy + comment controls
ALTER TABLE users
  ADD COLUMN is_private_account BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN comment_policy VARCHAR(16) NOT NULL DEFAULT 'everyone';

CREATE INDEX idx_users_is_private_account ON users (is_private_account);
CREATE INDEX idx_users_comment_policy ON users (comment_policy);

-- Mutes (viewer-side; hides content)
CREATE TABLE user_mutes (
  muter_id BIGINT NOT NULL,
  muted_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (muter_id, muted_id),
  CONSTRAINT fk_user_mutes_muter FOREIGN KEY (muter_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_mutes_muted FOREIGN KEY (muted_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_user_mutes_muter_id ON user_mutes (muter_id);
CREATE INDEX idx_user_mutes_muted_id ON user_mutes (muted_id);

-- Reports
CREATE TABLE reports (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  reporter_id BIGINT NOT NULL,
  target_type VARCHAR(24) NOT NULL,
  target_id BIGINT NOT NULL,
  reason VARCHAR(48) NOT NULL,
  details TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reports_reporter FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_reports_reporter_id_created_at ON reports (reporter_id, created_at);
CREATE INDEX idx_reports_target_type_target_id ON reports (target_type, target_id);
