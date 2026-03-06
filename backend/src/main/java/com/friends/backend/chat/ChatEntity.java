package com.friends.backend.chat;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "chats")
public class ChatEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "is_group", nullable = false)
  private boolean group;

  @Column
  private String title;

  @Column(name = "last_message", nullable = false, columnDefinition = "TEXT")
  private String lastMessage;

  @Column(name = "pinned_message_id")
  private Long pinnedMessageId;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @PrePersist
  void onCreate() {
    final Instant now = Instant.now();
    if (createdAt == null) createdAt = now;
    if (updatedAt == null) updatedAt = now;
    if (lastMessage == null) lastMessage = "";
  }

  @PreUpdate
  void onUpdate() {
    updatedAt = Instant.now();
  }

  public Long getId() { return id; }
  public boolean isGroup() { return group; }
  public void setGroup(boolean group) { this.group = group; }
  public String getTitle() { return title; }
  public void setTitle(String title) { this.title = title; }
  public String getLastMessage() { return lastMessage; }
  public void setLastMessage(String lastMessage) { this.lastMessage = lastMessage; }
  public Long getPinnedMessageId() { return pinnedMessageId; }
  public void setPinnedMessageId(Long pinnedMessageId) { this.pinnedMessageId = pinnedMessageId; }
  public Instant getCreatedAt() { return createdAt; }
  public Instant getUpdatedAt() { return updatedAt; }
  public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
