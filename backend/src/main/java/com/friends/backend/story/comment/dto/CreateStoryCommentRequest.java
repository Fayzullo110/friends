package com.friends.backend.story.comment.dto;

import jakarta.validation.constraints.NotBlank;

public class CreateStoryCommentRequest {
  @NotBlank
  public String text;
}
