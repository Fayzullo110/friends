package com.friends.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;

public class OAuthGoogleRequest {
  @NotBlank
  public String idToken;
}
