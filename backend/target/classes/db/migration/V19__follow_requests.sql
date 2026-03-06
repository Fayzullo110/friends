ALTER TABLE user_follows
  ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'accepted' AFTER created_at;

CREATE INDEX idx_user_follows_status ON user_follows (status);
CREATE INDEX idx_user_follows_following_status ON user_follows (following_id, status);
CREATE INDEX idx_user_follows_follower_status ON user_follows (follower_id, status);
