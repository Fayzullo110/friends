package com.friends.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;

public class OAuthFacebookRequest {
  @NotBlank
  public String accessToken;
}
