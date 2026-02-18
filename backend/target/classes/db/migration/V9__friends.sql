CREATE TABLE friend_requests (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  from_user_id BIGINT NOT NULL,
  to_user_id BIGINT NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_friend_requests_from_user FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_friend_requests_to_user FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_friend_requests_to_user_status_created ON friend_requests (to_user_id, status, created_at);
CREATE INDEX idx_friend_requests_from_to_status ON friend_requests (from_user_id, to_user_id, status);

CREATE TABLE friends (
  user_id BIGINT NOT NULL,
  friend_user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, friend_user_id),
  CONSTRAINT fk_friends_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_friends_friend FOREIGN KEY (friend_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_friends_user_id ON friends (user_id);
