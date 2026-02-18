package com.friends.backend.reel.dto;

import java.time.Instant;
import java.util.List;

public class ReelResponse {
  public long id;
  public long authorId;
  public String authorUsername;
  public String caption;
  public String mediaUrl;
  public String mediaType;
  public int likeCount;
  public List<Long> likedBy;
  public int commentCount;
  public int shareCount;
  public long createdAt;

  public Long archivedAt;
  public Long deletedAt;

  public ReelResponse(
      long id,
      long authorId,
      String authorUsername,
      String caption,
      String mediaUrl,
      String mediaType,
      int likeCount,
      List<Long> likedBy,
      int commentCount,
      int shareCount,
      Instant createdAt,
      Instant archivedAt,
      Instant deletedAt) {
    this.id = id;
    this.authorId = authorId;
    this.authorUsername = authorUsername;
    this.caption = caption;
    this.mediaUrl = mediaUrl;
    this.mediaType = mediaType;
    this.likeCount = likeCount;
    this.likedBy = likedBy;
    this.commentCount = commentCount;
    this.shareCount = shareCount;
    this.createdAt = createdAt == null ? 0L : createdAt.toEpochMilli();

    this.archivedAt = archivedAt == null ? null : archivedAt.toEpochMilli();
    this.deletedAt = deletedAt == null ? null : deletedAt.toEpochMilli();
  }
}
