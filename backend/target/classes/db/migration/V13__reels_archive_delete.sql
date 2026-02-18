ALTER TABLE reels
  ADD COLUMN archived_at TIMESTAMP NULL,
  ADD COLUMN deleted_at TIMESTAMP NULL;

CREATE INDEX idx_reels_archived_at ON reels (archived_at);
CREATE INDEX idx_reels_deleted_at ON reels (deleted_at);
