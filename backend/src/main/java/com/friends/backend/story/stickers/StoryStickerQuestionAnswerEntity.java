package com.friends.backend.story.stickers;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "story_sticker_question_answers")
public class StoryStickerQuestionAnswerEntity {
  @EmbeddedId
  private StoryStickerQuestionAnswerId id;

  @Column(name = "answer_text", nullable = false, columnDefinition = "TEXT")
  private String answerText;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  public StoryStickerQuestionAnswerEntity() {}

  public StoryStickerQuestionAnswerEntity(StoryStickerQuestionAnswerId id, String answerText) {
    this.id = id;
    this.answerText = answerText;
  }

  @PrePersist
  void onCreate() {
    if (createdAt == null) createdAt = Instant.now();
  }

  public StoryStickerQuestionAnswerId getId() { return id; }
  public String getAnswerText() { return answerText; }
  public void setAnswerText(String answerText) { this.answerText = answerText; }
  public Instant getCreatedAt() { return createdAt; }
}
