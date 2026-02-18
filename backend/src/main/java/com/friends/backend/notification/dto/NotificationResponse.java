package com.friends.backend.notification.dto;

import java.time.Instant;

public class NotificationResponse {
  public String id;
  public String type;
  public String fromUserId;
  public String fromUsername;
  public String postId;
  public long createdAt;
  public boolean isRead;

  public NotificationResponse(
      long id,
      String type,
      long fromUserId,
      String fromUsername,
      Long postId,
      Instant createdAt,
      boolean isRead) {
    this.id = Long.toString(id);
    this.type = type;
    this.fromUserId = Long.toString(fromUserId);
    this.fromUsername = fromUsername;
    this.postId = postId == null ? null : Long.toString(postId);
    this.createdAt = createdAt == null ? 0L : createdAt.toEpochMilli();
    this.isRead = isRead;
  }
}
