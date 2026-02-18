package com.friends.backend.status.dto;

import jakarta.validation.constraints.NotBlank;

public class CreateStatusRequest {
  @NotBlank
  public String text;

  public String emoji;
  public String musicTitle;
  public String musicArtist;
  public String musicUrl;
}
