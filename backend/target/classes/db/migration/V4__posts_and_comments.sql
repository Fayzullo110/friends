CREATE TABLE posts (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  author_id BIGINT NOT NULL,
  text TEXT NOT NULL,
  media_url TEXT NULL,
  media_type VARCHAR(10) NOT NULL DEFAULT 'text',
  pinned_comment_id BIGINT NULL,
  like_count INT NOT NULL DEFAULT 0,
  comment_count INT NOT NULL DEFAULT 0,
  share_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_posts_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_posts_created_at ON posts (created_at);
CREATE INDEX idx_posts_author_id ON posts (author_id);

CREATE TABLE post_likes (
  post_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (post_id, user_id),
  CONSTRAINT fk_post_likes_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  CONSTRAINT fk_post_likes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_post_likes_post_id ON post_likes (post_id);
CREATE INDEX idx_post_likes_user_id ON post_likes (user_id);

CREATE TABLE comments (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  post_id BIGINT NOT NULL,
  author_id BIGINT NOT NULL,
  text TEXT NOT NULL,
  type VARCHAR(10) NOT NULL DEFAULT 'text',
  media_url TEXT NULL,
  parent_comment_id BIGINT NULL,
  like_count INT NOT NULL DEFAULT 0,
  dislike_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_comments_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
  CONSTRAINT fk_comments_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_comments_parent FOREIGN KEY (parent_comment_id) REFERENCES comments(id) ON DELETE SET NULL
);

CREATE INDEX idx_comments_post_id_created ON comments (post_id, created_at);

CREATE TABLE comment_likes (
  comment_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (comment_id, user_id),
  CONSTRAINT fk_comment_likes_comment FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
  CONSTRAINT fk_comment_likes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE comment_dislikes (
  comment_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (comment_id, user_id),
  CONSTRAINT fk_comment_dislikes_comment FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
  CONSTRAINT fk_comment_dislikes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
