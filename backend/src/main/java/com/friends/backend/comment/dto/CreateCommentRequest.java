package com.friends.backend.comment.dto;

public class CreateCommentRequest {
  public String text;

  public String type; // text,gif

  public String mediaUrl;

  public Long parentCommentId;
}
