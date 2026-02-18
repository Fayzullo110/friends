CREATE TABLE user_blocks (
  blocker_id BIGINT NOT NULL,
  blocked_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (blocker_id, blocked_id),
  CONSTRAINT fk_user_blocks_blocker FOREIGN KEY (blocker_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_blocks_blocked FOREIGN KEY (blocked_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_user_blocks_blocker ON user_blocks (blocker_id);
CREATE INDEX idx_user_blocks_blocked ON user_blocks (blocked_id);

CREATE TABLE user_follows (
  follower_id BIGINT NOT NULL,
  following_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (follower_id, following_id),
  CONSTRAINT fk_user_follows_follower FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_follows_following FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_user_follows_follower ON user_follows (follower_id);
CREATE INDEX idx_user_follows_following ON user_follows (following_id);
