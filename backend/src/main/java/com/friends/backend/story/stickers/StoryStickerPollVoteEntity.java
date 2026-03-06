package com.friends.backend.story.stickers;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "story_sticker_poll_votes")
public class StoryStickerPollVoteEntity {
  @EmbeddedId
  private StoryStickerPollVoteId id;

  @Column(name = "option_index", nullable = false)
  private int optionIndex;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  public StoryStickerPollVoteEntity() {}

  public StoryStickerPollVoteEntity(StoryStickerPollVoteId id, int optionIndex) {
    this.id = id;
    this.optionIndex = optionIndex;
  }

  @PrePersist
  void onCreate() {
    if (createdAt == null) createdAt = Instant.now();
  }

  public StoryStickerPollVoteId getId() { return id; }
  public int getOptionIndex() { return optionIndex; }
  public void setOptionIndex(int optionIndex) { this.optionIndex = optionIndex; }
  public Instant getCreatedAt() { return createdAt; }
}
