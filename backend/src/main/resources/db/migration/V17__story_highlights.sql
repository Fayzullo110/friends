CREATE TABLE story_highlights (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  owner_id BIGINT NOT NULL,
  title VARCHAR(80) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_story_highlights_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_story_highlights_owner_id ON story_highlights (owner_id);

CREATE TABLE story_highlight_items (
  highlight_id BIGINT NOT NULL,
  story_id BIGINT NOT NULL,
  position INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (highlight_id, story_id),
  CONSTRAINT fk_story_highlight_items_highlight FOREIGN KEY (highlight_id) REFERENCES story_highlights(id) ON DELETE CASCADE,
  CONSTRAINT fk_story_highlight_items_story FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE
);

CREATE INDEX idx_story_highlight_items_highlight_id_position ON story_highlight_items (highlight_id, position);
