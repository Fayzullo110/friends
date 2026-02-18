package com.friends.backend.auth.dto;

public class AuthResponse {
  public String accessToken;
  public UserResponse user;

  public AuthResponse(String accessToken, UserResponse user) {
    this.accessToken = accessToken;
    this.user = user;
  }
}
