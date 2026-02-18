package com.friends.backend.chat;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "chat_typing")
public class ChatTypingEntity {
  @EmbeddedId
  private ChatTypingId id;

  @Column(name = "is_typing", nullable = false)
  private boolean typing;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  public ChatTypingEntity() {}

  public ChatTypingEntity(ChatTypingId id, boolean typing) {
    this.id = id;
    this.typing = typing;
  }

  @PrePersist
  void onCreate() {
    if (updatedAt == null) updatedAt = Instant.now();
  }

  @PreUpdate
  void onUpdate() {
    updatedAt = Instant.now();
  }

  public ChatTypingId getId() {
    return id;
  }

  public void setId(ChatTypingId id) {
    this.id = id;
  }

  public boolean isTyping() {
    return typing;
  }

  public void setTyping(boolean typing) {
    this.typing = typing;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public void setUpdatedAt(Instant updatedAt) {
    this.updatedAt = updatedAt;
  }
}
