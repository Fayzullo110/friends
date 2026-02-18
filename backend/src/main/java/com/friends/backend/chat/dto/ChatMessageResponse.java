package com.friends.backend.chat.dto;

import java.time.Instant;
import java.util.List;
import java.util.Map;

public class ChatMessageResponse {
  public long id;
  public long senderId;
  public String senderUsername;
  public String type;
  public String text;
  public String mediaUrl;
  public long createdAt;
  public Map<String, List<Long>> reactions;
  public List<Long> seenBy;

  public ChatMessageResponse(
      long id,
      long senderId,
      String senderUsername,
      String type,
      String text,
      String mediaUrl,
      Instant createdAt,
      Map<String, List<Long>> reactions,
      List<Long> seenBy) {
    this.id = id;
    this.senderId = senderId;
    this.senderUsername = senderUsername;
    this.type = type;
    this.text = text;
    this.mediaUrl = mediaUrl;
    this.createdAt = createdAt == null ? 0L : createdAt.toEpochMilli();
    this.reactions = reactions;
    this.seenBy = seenBy;
  }
}
