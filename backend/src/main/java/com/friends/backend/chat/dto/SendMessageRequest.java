package com.friends.backend.chat.dto;

public class SendMessageRequest {
  public String type; // text,gif,voice,video,image,file
  public String text;
  public String mediaUrl;
  public Long replyToMessageId;
}
