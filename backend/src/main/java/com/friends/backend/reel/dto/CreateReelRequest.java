package com.friends.backend.reel.dto;

import jakarta.validation.constraints.NotBlank;

public class CreateReelRequest {
  @NotBlank
  public String caption;

  public String mediaUrl;

  public String mediaType;
}
