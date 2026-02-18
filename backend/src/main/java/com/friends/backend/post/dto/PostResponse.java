package com.friends.backend.post.dto;

import java.time.Instant;
import java.util.List;

public class PostResponse {
  public long id;
  public long authorId;
  public String authorUsername;
  public String authorPhotoUrl;
  public String text;
  public String mediaUrl;
  public String mediaType;
  public long createdAt;
  public int likeCount;
  public List<Long> likedBy;
  public int commentCount;
  public int shareCount;
  public Long pinnedCommentId;
  public Long archivedAt;
  public Long deletedAt;

  public PostResponse(
      long id,
      long authorId,
      String authorUsername,
      String authorPhotoUrl,
      String text,
      String mediaUrl,
      String mediaType,
      Instant createdAt,
      int likeCount,
      List<Long> likedBy,
      int commentCount,
      int shareCount,
      Long pinnedCommentId,
      Instant archivedAt,
      Instant deletedAt) {
    this.id = id;
    this.authorId = authorId;
    this.authorUsername = authorUsername;
    this.authorPhotoUrl = authorPhotoUrl;
    this.text = text;
    this.mediaUrl = mediaUrl;
    this.mediaType = mediaType;
    this.createdAt = createdAt == null ? 0L : createdAt.toEpochMilli();
    this.likeCount = likeCount;
    this.likedBy = likedBy;
    this.commentCount = commentCount;
    this.shareCount = shareCount;
    this.pinnedCommentId = pinnedCommentId;
    this.archivedAt = archivedAt == null ? null : archivedAt.toEpochMilli();
    this.deletedAt = deletedAt == null ? null : deletedAt.toEpochMilli();
  }
}
