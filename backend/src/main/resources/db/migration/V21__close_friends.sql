CREATE TABLE close_friends (
  user_id BIGINT NOT NULL,
  close_friend_user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, close_friend_user_id),
  CONSTRAINT fk_close_friends_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_close_friends_close_friend FOREIGN KEY (close_friend_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_close_friends_user ON close_friends (user_id);
