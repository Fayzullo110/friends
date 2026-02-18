package com.friends.backend.chat;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "chat_members")
public class ChatMemberEntity {
  @EmbeddedId
  private ChatMemberId id;

  protected ChatMemberEntity() {}

  public ChatMemberEntity(ChatMemberId id) { this.id = id; }

  public ChatMemberId getId() { return id; }
}
