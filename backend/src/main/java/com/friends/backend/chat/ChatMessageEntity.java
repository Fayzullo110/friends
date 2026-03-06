package com.friends.backend.chat;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "chat_messages")
public class ChatMessageEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "chat_id", nullable = false)
  private Long chatId;

  @Column(name = "sender_id", nullable = false)
  private Long senderId;

  @Column(nullable = false)
  private String type;

  @Column(columnDefinition = "TEXT")
  private String text;

  @Column(name = "media_url", columnDefinition = "TEXT")
  private String mediaUrl;

  @Column(name = "reply_to_message_id")
  private Long replyToMessageId;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @PrePersist
  void onCreate() {
    if (createdAt == null) createdAt = Instant.now();
  }

  public Long getId() { return id; }
  public Long getChatId() { return chatId; }
  public void setChatId(Long chatId) { this.chatId = chatId; }
  public Long getSenderId() { return senderId; }
  public void setSenderId(Long senderId) { this.senderId = senderId; }
  public String getType() { return type; }
  public void setType(String type) { this.type = type; }
  public String getText() { return text; }
  public void setText(String text) { this.text = text; }
  public String getMediaUrl() { return mediaUrl; }
  public void setMediaUrl(String mediaUrl) { this.mediaUrl = mediaUrl; }
  public Long getReplyToMessageId() { return replyToMessageId; }
  public void setReplyToMessageId(Long replyToMessageId) { this.replyToMessageId = replyToMessageId; }
  public Instant getCreatedAt() { return createdAt; }
}
