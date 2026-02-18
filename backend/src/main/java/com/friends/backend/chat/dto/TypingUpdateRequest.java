package com.friends.backend.chat.dto;

import jakarta.validation.constraints.NotNull;

public class TypingUpdateRequest {
  @NotNull
  public Boolean isTyping;
}
