package com.friends.backend.user.dto;

import jakarta.validation.constraints.Size;

public class UpdateMeRequest {
  @Size(min = 3, max = 50)
  public String username;

  @Size(max = 200)
  public String bio;

  public String photoUrl;

  public String backgroundImageUrl;

  public String themeKey;

  public Integer themeSeedColor;

  public Boolean isPrivateAccount;

  public String commentPolicy; // everyone | followers | no_one
}
