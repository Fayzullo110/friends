package com.friends.backend.chat.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public class CreateGroupChatRequest {
  @NotBlank
  public String title;

  @NotEmpty
  public List<Long> memberIds;
}
