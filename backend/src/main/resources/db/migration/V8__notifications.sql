CREATE TABLE notifications (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  to_user_id BIGINT NOT NULL,
  from_user_id BIGINT NOT NULL,
  type VARCHAR(32) NOT NULL,
  post_id BIGINT NULL,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notifications_to_user FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_notifications_from_user FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_notifications_to_user_created ON notifications (to_user_id, created_at);
CREATE INDEX idx_notifications_to_user_is_read ON notifications (to_user_id, is_read);
