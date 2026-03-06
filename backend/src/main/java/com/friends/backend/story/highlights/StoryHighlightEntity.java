package com.friends.backend.story.highlights;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "story_highlights")
public class StoryHighlightEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "owner_id", nullable = false)
  private Long ownerId;

  @Column(nullable = false)
  private String title;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @PrePersist
  void onCreate() {
    final Instant now = Instant.now();
    if (createdAt == null) createdAt = now;
    if (updatedAt == null) updatedAt = now;
  }

  @PreUpdate
  void onUpdate() {
    updatedAt = Instant.now();
  }

  public Long getId() { return id; }
  public Long getOwnerId() { return ownerId; }
  public void setOwnerId(Long ownerId) { this.ownerId = ownerId; }
  public String getTitle() { return title; }
  public void setTitle(String title) { this.title = title; }
  public Instant getCreatedAt() { return createdAt; }
  public Instant getUpdatedAt() { return updatedAt; }
}
