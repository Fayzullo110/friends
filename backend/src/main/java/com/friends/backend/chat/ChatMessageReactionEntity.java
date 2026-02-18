package com.friends.backend.chat;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "chat_message_reactions")
public class ChatMessageReactionEntity {
  @EmbeddedId
  private ChatMessageReactionId id;

  protected ChatMessageReactionEntity() {}

  public ChatMessageReactionEntity(ChatMessageReactionId id) { this.id = id; }

  public ChatMessageReactionId getId() { return id; }
}
