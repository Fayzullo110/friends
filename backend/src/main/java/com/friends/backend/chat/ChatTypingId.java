package com.friends.backend.chat;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class ChatTypingId implements Serializable {
  @Column(name = "chat_id")
  private Long chatId;

  @Column(name = "user_id")
  private Long userId;

  public ChatTypingId() {}

  public ChatTypingId(Long chatId, Long userId) {
    this.chatId = chatId;
    this.userId = userId;
  }

  public Long getChatId() {
    return chatId;
  }

  public Long getUserId() {
    return userId;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    ChatTypingId that = (ChatTypingId) o;
    return Objects.equals(chatId, that.chatId) && Objects.equals(userId, that.userId);
  }

  @Override
  public int hashCode() {
    return Objects.hash(chatId, userId);
  }
}
