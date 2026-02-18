CREATE TABLE stories (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  author_id BIGINT NOT NULL,
  media_url TEXT NULL,
  media_type VARCHAR(10) NOT NULL DEFAULT 'text',
  text TEXT NULL,
  music_title VARCHAR(255) NULL,
  music_artist VARCHAR(255) NULL,
  music_url TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  CONSTRAINT fk_stories_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_stories_expires_at ON stories (expires_at);
CREATE INDEX idx_stories_author_id ON stories (author_id);

CREATE TABLE story_seen (
  story_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (story_id, user_id),
  CONSTRAINT fk_story_seen_story FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE,
  CONSTRAINT fk_story_seen_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE story_likes (
  story_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (story_id, user_id),
  CONSTRAINT fk_story_likes_story FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE,
  CONSTRAINT fk_story_likes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE story_comments (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  story_id BIGINT NOT NULL,
  author_id BIGINT NOT NULL,
  text TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_story_comments_story FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE,
  CONSTRAINT fk_story_comments_author FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_story_comments_story_id_created ON story_comments (story_id, created_at);

CREATE TABLE user_statuses (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  text TEXT NOT NULL,
  emoji VARCHAR(16) NULL,
  music_title VARCHAR(255) NULL,
  music_artist VARCHAR(255) NULL,
  music_url TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP NOT NULL,
  CONSTRAINT fk_user_statuses_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_user_statuses_expires_at ON user_statuses (expires_at);
CREATE INDEX idx_user_statuses_user_id ON user_statuses (user_id);

CREATE TABLE user_status_seen (
  status_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (status_id, user_id),
  CONSTRAINT fk_user_status_seen_status FOREIGN KEY (status_id) REFERENCES user_statuses(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_status_seen_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
