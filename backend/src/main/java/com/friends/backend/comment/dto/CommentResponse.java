package com.friends.backend.comment.dto;

import java.time.Instant;
import java.util.List;

public class CommentResponse {
  public long id;
  public long postId;
  public long authorId;
  public String authorUsername;
  public String authorPhotoUrl;
  public String text;
  public String type;
  public String mediaUrl;
  public long createdAt;
  public int likeCount;
  public List<Long> likedBy;
  public Long parentCommentId;
  public int dislikeCount;
  public List<Long> dislikedBy;

  public CommentResponse(
      long id,
      long postId,
      long authorId,
      String authorUsername,
      String authorPhotoUrl,
      String text,
      String type,
      String mediaUrl,
      Instant createdAt,
      int likeCount,
      List<Long> likedBy,
      Long parentCommentId,
      int dislikeCount,
      List<Long> dislikedBy) {
    this.id = id;
    this.postId = postId;
    this.authorId = authorId;
    this.authorUsername = authorUsername;
    this.authorPhotoUrl = authorPhotoUrl;
    this.text = text;
    this.type = type;
    this.mediaUrl = mediaUrl;
    this.createdAt = createdAt == null ? 0L : createdAt.toEpochMilli();
    this.likeCount = likeCount;
    this.likedBy = likedBy;
    this.parentCommentId = parentCommentId;
    this.dislikeCount = dislikeCount;
    this.dislikedBy = dislikedBy;
  }
}
