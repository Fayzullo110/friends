package com.friends.backend.story.comment;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "story_comments")
public class StoryCommentEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "story_id", nullable = false)
  private Long storyId;

  @Column(name = "author_id", nullable = false)
  private Long authorId;

  @Column(nullable = false, columnDefinition = "TEXT")
  private String text;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @PrePersist
  void onCreate() { if (createdAt == null) createdAt = Instant.now(); }

  public Long getId() { return id; }
  public Long getStoryId() { return storyId; }
  public void setStoryId(Long storyId) { this.storyId = storyId; }
  public Long getAuthorId() { return authorId; }
  public void setAuthorId(Long authorId) { this.authorId = authorId; }
  public String getText() { return text; }
  public void setText(String text) { this.text = text; }
  public Instant getCreatedAt() { return createdAt; }
}
