CREATE TABLE chats (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  is_group BOOLEAN NOT NULL DEFAULT FALSE,
  title VARCHAR(255) NULL,
  last_message VARCHAR(255) NOT NULL DEFAULT '',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chats_updated_at ON chats (updated_at);

CREATE TABLE chat_members (
  chat_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (chat_id, user_id),
  CONSTRAINT fk_chat_members_chat FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
  CONSTRAINT fk_chat_members_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_chat_members_user_id ON chat_members (user_id);

CREATE TABLE chat_messages (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  chat_id BIGINT NOT NULL,
  sender_id BIGINT NOT NULL,
  type VARCHAR(10) NOT NULL DEFAULT 'text',
  text TEXT NULL,
  media_url TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_chat_messages_chat FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
  CONSTRAINT fk_chat_messages_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX idx_chat_messages_chat_id_created ON chat_messages (chat_id, created_at);

CREATE TABLE chat_message_seen (
  message_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (message_id, user_id),
  CONSTRAINT fk_chat_message_seen_message FOREIGN KEY (message_id) REFERENCES chat_messages(id) ON DELETE CASCADE,
  CONSTRAINT fk_chat_message_seen_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE chat_message_reactions (
  message_id BIGINT NOT NULL,
  emoji VARCHAR(32) NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (message_id, emoji, user_id),
  CONSTRAINT fk_chat_message_reactions_message FOREIGN KEY (message_id) REFERENCES chat_messages(id) ON DELETE CASCADE,
  CONSTRAINT fk_chat_message_reactions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
