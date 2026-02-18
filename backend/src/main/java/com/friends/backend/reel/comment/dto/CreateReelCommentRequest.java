package com.friends.backend.reel.comment.dto;

import jakarta.validation.constraints.NotBlank;

public class CreateReelCommentRequest {
  @NotBlank
  public String text;

  public String type; // text,gif

  public String mediaUrl;
}
