package com.friends.backend.chat;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class ChatMessageSeenId implements Serializable {
  @Column(name = "message_id")
  private Long messageId;

  @Column(name = "user_id")
  private Long userId;

  protected ChatMessageSeenId() {}

  public ChatMessageSeenId(Long messageId, Long userId) {
    this.messageId = messageId;
    this.userId = userId;
  }

  public Long getMessageId() { return messageId; }
  public Long getUserId() { return userId; }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    ChatMessageSeenId that = (ChatMessageSeenId) o;
    return Objects.equals(messageId, that.messageId) && Objects.equals(userId, that.userId);
  }

  @Override
  public int hashCode() { return Objects.hash(messageId, userId); }
}
