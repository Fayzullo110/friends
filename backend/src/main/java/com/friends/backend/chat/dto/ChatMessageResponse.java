package com.friends.backend.chat.dto;

import java.time.Instant;
import java.util.List;
import java.util.Map;

public class ChatMessageResponse {
  public long id;
  public long senderId;
  public String senderUsername;
  public String senderPhotoUrl;
  public String type;
  public String text;
  public String mediaUrl;
  public Long replyToMessageId;
  public Long replyToSenderId;
  public String replyToSenderUsername;
  public String replyToType;
  public String replyToText;
  public String replyToMediaUrl;
  public long createdAt;
  public Map<String, List<Long>> reactions;
  public List<Long> seenBy;

  public ChatMessageResponse(
      long id,
      long senderId,
      String senderUsername,
      String senderPhotoUrl,
      String type,
      String text,
      String mediaUrl,
      Long replyToMessageId,
      Long replyToSenderId,
      String replyToSenderUsername,
      String replyToType,
      String replyToText,
      String replyToMediaUrl,
      Instant createdAt,
      Map<String, List<Long>> reactions,
      List<Long> seenBy) {
    this.id = id;
    this.senderId = senderId;
    this.senderUsername = senderUsername;
    this.senderPhotoUrl = senderPhotoUrl;
    this.type = type;
    this.text = text;
    this.mediaUrl = mediaUrl;
    this.replyToMessageId = replyToMessageId;
    this.replyToSenderId = replyToSenderId;
    this.replyToSenderUsername = replyToSenderUsername;
    this.replyToType = replyToType;
    this.replyToText = replyToText;
    this.replyToMediaUrl = replyToMediaUrl;
    this.createdAt = createdAt == null ? 0L : createdAt.toEpochMilli();
    this.reactions = reactions;
    this.seenBy = seenBy;
  }
}
