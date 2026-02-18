CREATE TABLE reels (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  author_id BIGINT NOT NULL,
  caption TEXT NOT NULL,
  media_url TEXT NULL,
  media_type VARCHAR(10) NOT NULL DEFAULT 'video',
  like_count INT NOT NULL DEFAULT 0,
  comment_count INT NOT NULL DEFAULT 0,
  share_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reels_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_reels_created_at ON reels (created_at);
CREATE INDEX idx_reels_author_id ON reels (author_id);

CREATE TABLE reel_likes (
  reel_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (reel_id, user_id),
  CONSTRAINT fk_reel_likes_reel FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE,
  CONSTRAINT fk_reel_likes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE reel_comments (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  reel_id BIGINT NOT NULL,
  author_id BIGINT NOT NULL,
  text TEXT NOT NULL,
  type VARCHAR(10) NOT NULL DEFAULT 'text',
  media_url TEXT NULL,
  like_count INT NOT NULL DEFAULT 0,
  dislike_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reel_comments_reel FOREIGN KEY (reel_id) REFERENCES reels(id) ON DELETE CASCADE,
  CONSTRAINT fk_reel_comments_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_reel_comments_reel_id_created ON reel_comments (reel_id, created_at);

CREATE TABLE reel_comment_likes (
  comment_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (comment_id, user_id),
  CONSTRAINT fk_reel_comment_likes_comment FOREIGN KEY (comment_id) REFERENCES reel_comments(id) ON DELETE CASCADE,
  CONSTRAINT fk_reel_comment_likes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE reel_comment_dislikes (
  comment_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (comment_id, user_id),
  CONSTRAINT fk_reel_comment_dislikes_comment FOREIGN KEY (comment_id) REFERENCES reel_comments(id) ON DELETE CASCADE,
  CONSTRAINT fk_reel_comment_dislikes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
