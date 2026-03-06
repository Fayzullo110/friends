package com.friends.backend.story.highlights;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "story_highlight_items")
public class StoryHighlightItemEntity {
  @EmbeddedId
  private StoryHighlightItemId id;

  @Column(nullable = false)
  private int position;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  public StoryHighlightItemEntity() {}

  public StoryHighlightItemEntity(StoryHighlightItemId id, int position) {
    this.id = id;
    this.position = position;
  }

  @PrePersist
  void onCreate() {
    if (createdAt == null) createdAt = Instant.now();
  }

  public StoryHighlightItemId getId() { return id; }
  public int getPosition() { return position; }
  public void setPosition(int position) { this.position = position; }
  public Instant getCreatedAt() { return createdAt; }
}
