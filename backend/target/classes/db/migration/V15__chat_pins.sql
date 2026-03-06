ALTER TABLE chats
  ADD COLUMN pinned_message_id BIGINT NULL;

CREATE INDEX idx_chats_pinned_message_id ON chats (pinned_message_id);

ALTER TABLE chats
  ADD CONSTRAINT fk_chats_pinned_message
    FOREIGN KEY (pinned_message_id)
    REFERENCES chat_messages(id)
    ON DELETE SET NULL;
