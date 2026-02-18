package com.friends.backend.friend.dto;

import java.time.Instant;

public class FriendRequestResponse {
  public String id;
  public String fromUserId;
  public String toUserId;
  public String fromUsername;
  public long createdAt;
  public String status;

  public FriendRequestResponse(
      long id,
      long fromUserId,
      long toUserId,
      String fromUsername,
      Instant createdAt,
      String status) {
    this.id = Long.toString(id);
    this.fromUserId = Long.toString(fromUserId);
    this.toUserId = Long.toString(toUserId);
    this.fromUsername = fromUsername;
    this.createdAt = createdAt == null ? 0L : createdAt.toEpochMilli();
    this.status = status;
  }
}
