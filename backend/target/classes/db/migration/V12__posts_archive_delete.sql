ALTER TABLE posts
  ADD COLUMN archived_at TIMESTAMP NULL,
  ADD COLUMN deleted_at TIMESTAMP NULL;

CREATE INDEX idx_posts_archived_at ON posts (archived_at);
CREATE INDEX idx_posts_deleted_at ON posts (deleted_at);
