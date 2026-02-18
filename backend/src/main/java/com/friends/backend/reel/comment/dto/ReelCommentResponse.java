package com.friends.backend.reel.comment.dto;

import java.time.Instant;
import java.util.List;

public class ReelCommentResponse {
  public long id;
  public long reelId;
  public long authorId;
  public String authorUsername;
  public String text;
  public String type;
  public String mediaUrl;
  public long createdAt;
  public int likeCount;
  public List<Long> likedBy;
  public int dislikeCount;
  public List<Long> dislikedBy;

  public ReelCommentResponse(
      long id,
      long reelId,
      long authorId,
      String authorUsername,
      String text,
      String type,
      String mediaUrl,
      Instant createdAt,
      int likeCount,
      List<Long> likedBy,
      int dislikeCount,
      List<Long> dislikedBy) {
    this.id = id;
    this.reelId = reelId;
    this.authorId = authorId;
    this.authorUsername = authorUsername;
    this.text = text;
    this.type = type;
    this.mediaUrl = mediaUrl;
    this.createdAt = createdAt == null ? 0L : createdAt.toEpochMilli();
    this.likeCount = likeCount;
    this.likedBy = likedBy;
    this.dislikeCount = dislikeCount;
    this.dislikedBy = dislikedBy;
  }
}
