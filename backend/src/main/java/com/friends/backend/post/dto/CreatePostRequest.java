package com.friends.backend.post.dto;

import jakarta.validation.constraints.NotBlank;

public class CreatePostRequest {
  @NotBlank
  public String text;

  public String mediaUrl;

  public String mediaType; // text,image,video
}
