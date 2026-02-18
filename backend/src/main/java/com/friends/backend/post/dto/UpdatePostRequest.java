package com.friends.backend.post.dto;

import jakarta.validation.constraints.NotBlank;

public class UpdatePostRequest {
  @NotBlank
  public String text;
}
