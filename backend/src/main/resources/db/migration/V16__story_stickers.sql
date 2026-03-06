CREATE TABLE story_stickers (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  story_id BIGINT NOT NULL,
  type VARCHAR(16) NOT NULL,
  pos_x DOUBLE NOT NULL,
  pos_y DOUBLE NOT NULL,
  data_json TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_story_stickers_story FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE
);

CREATE INDEX idx_story_stickers_story_id ON story_stickers (story_id);

-- Poll votes: one vote per user per sticker
CREATE TABLE story_sticker_poll_votes (
  sticker_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  option_index INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (sticker_id, user_id),
  CONSTRAINT fk_story_sticker_poll_votes_sticker FOREIGN KEY (sticker_id) REFERENCES story_stickers(id) ON DELETE CASCADE,
  CONSTRAINT fk_story_sticker_poll_votes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_story_sticker_poll_votes_sticker_id ON story_sticker_poll_votes (sticker_id);

-- Question answers: one latest answer per user per sticker
CREATE TABLE story_sticker_question_answers (
  sticker_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  answer_text TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (sticker_id, user_id),
  CONSTRAINT fk_story_sticker_question_answers_sticker FOREIGN KEY (sticker_id) REFERENCES story_stickers(id) ON DELETE CASCADE,
  CONSTRAINT fk_story_sticker_question_answers_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_story_sticker_question_answers_sticker_id ON story_sticker_question_answers (sticker_id);

-- Emoji slider: one latest value per user per sticker (0..100)
CREATE TABLE story_sticker_emoji_slider_values (
  sticker_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  value_int INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (sticker_id, user_id),
  CONSTRAINT fk_story_sticker_emoji_slider_values_sticker FOREIGN KEY (sticker_id) REFERENCES story_stickers(id) ON DELETE CASCADE,
  CONSTRAINT fk_story_sticker_emoji_slider_values_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_story_sticker_emoji_slider_values_sticker_id ON story_sticker_emoji_slider_values (sticker_id);
