package com.friends.backend.chat.dto;

import java.time.Instant;
import java.util.List;
import java.util.Map;

public class ChatResponse {
  public long id;
  public List<Long> members;
  public Map<Long, String> memberUsernames;
  public String lastMessage;
  public long updatedAt;
  public boolean isGroup;
  public String title;

  public ChatResponse(
      long id,
      List<Long> members,
      Map<Long, String> memberUsernames,
      String lastMessage,
      Instant updatedAt,
      boolean isGroup,
      String title) {
    this.id = id;
    this.members = members;
    this.memberUsernames = memberUsernames;
    this.lastMessage = lastMessage;
    this.updatedAt = updatedAt == null ? 0L : updatedAt.toEpochMilli();
    this.isGroup = isGroup;
    this.title = title;
  }
}
