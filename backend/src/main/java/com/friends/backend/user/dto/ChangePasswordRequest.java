package com.friends.backend.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class ChangePasswordRequest {
  @NotBlank
  public String oldPassword;

  @NotBlank
  @Size(min = 8, max = 100)
  public String newPassword;
}
