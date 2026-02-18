CREATE TABLE chat_typing (
  chat_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  is_typing BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (chat_id, user_id),
  CONSTRAINT fk_chat_typing_chat FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
  CONSTRAINT fk_chat_typing_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_chat_typing_chat_updated ON chat_typing (chat_id, updated_at);
