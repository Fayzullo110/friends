package com.friends.backend.story.comment.dto;

import java.time.Instant;

public class StoryCommentResponse {
  public long id;
  public long storyId;
  public long authorId;
  public String authorUsername;
  public String text;
  public long createdAt;

  public StoryCommentResponse(long id, long storyId, long authorId, String authorUsername, String text, Instant createdAt) {
    this.id = id;
    this.storyId = storyId;
    this.authorId = authorId;
    this.authorUsername = authorUsername;
    this.text = text;
    this.createdAt = createdAt == null ? 0L : createdAt.toEpochMilli();
  }
}
