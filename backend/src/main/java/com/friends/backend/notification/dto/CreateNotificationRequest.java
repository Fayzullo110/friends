package com.friends.backend.notification.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class CreateNotificationRequest {
  @NotNull
  public Long toUserId;

  @NotBlank
  public String type;

  public Long postId;
}
