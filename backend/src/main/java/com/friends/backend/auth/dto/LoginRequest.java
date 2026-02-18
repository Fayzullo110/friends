package com.friends.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;

public class LoginRequest {
  @NotBlank
  public String identifier; // email or username

  @NotBlank
  public String password;
}
