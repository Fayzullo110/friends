package com.friends.backend.chat;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class ChatMessageReactionId implements Serializable {
  @Column(name = "message_id")
  private Long messageId;

  @Column
  private String emoji;

  @Column(name = "user_id")
  private Long userId;

  protected ChatMessageReactionId() {}

  public ChatMessageReactionId(Long messageId, String emoji, Long userId) {
    this.messageId = messageId;
    this.emoji = emoji;
    this.userId = userId;
  }

  public Long getMessageId() { return messageId; }
  public String getEmoji() { return emoji; }
  public Long getUserId() { return userId; }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    ChatMessageReactionId that = (ChatMessageReactionId) o;
    return Objects.equals(messageId, that.messageId)
        && Objects.equals(emoji, that.emoji)
        && Objects.equals(userId, that.userId);
  }

  @Override
  public int hashCode() { return Objects.hash(messageId, emoji, userId); }
}
