package com.friends.backend.auth.dto;

public class UserResponse {
  public long id;
  public String email;
  public String username;
  public String firstName;
  public String lastName;
  public Integer age;
  public String photoUrl;
  public String bio;
  public String backgroundImageUrl;
  public String themeKey;
  public Integer themeSeedColor;
  public boolean isOnline;
  public String lastActiveAt;

  public UserResponse(
      long id,
      String email,
      String username,
      String firstName,
      String lastName,
      Integer age,
      String photoUrl,
      String bio,
      String backgroundImageUrl,
      String themeKey,
      Integer themeSeedColor,
      boolean isOnline,
      String lastActiveAt) {
    this.id = id;
    this.email = email;
    this.username = username;
    this.firstName = firstName;
    this.lastName = lastName;
    this.age = age;
    this.photoUrl = photoUrl;
    this.bio = bio;
    this.backgroundImageUrl = backgroundImageUrl;
    this.themeKey = themeKey;
    this.themeSeedColor = themeSeedColor;
    this.isOnline = isOnline;
    this.lastActiveAt = lastActiveAt;
  }
}
