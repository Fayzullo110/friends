package com.friends.backend.user.dto;

public class UserSearchResponse {
  public long id;
  public String email;
  public String username;
  public String photoUrl;

  public UserSearchResponse(long id, String email, String username, String photoUrl) {
    this.id = id;
    this.email = email;
    this.username = username;
    this.photoUrl = photoUrl;
  }
}
