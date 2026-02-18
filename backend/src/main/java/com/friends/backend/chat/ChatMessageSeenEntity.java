package com.friends.backend.chat;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "chat_message_seen")
public class ChatMessageSeenEntity {
  @EmbeddedId
  private ChatMessageSeenId id;

  protected ChatMessageSeenEntity() {}

  public ChatMessageSeenEntity(ChatMessageSeenId id) { this.id = id; }

  public ChatMessageSeenId getId() { return id; }
}
