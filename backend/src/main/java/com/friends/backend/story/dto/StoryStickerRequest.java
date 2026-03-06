package com.friends.backend.story.dto;

public class StoryStickerRequest {
  public String type; // poll,question,emoji_slider
  public Double posX; // 0..1 relative
  public Double posY; // 0..1 relative
  public String dataJson; // sticker-specific payload (question/options/emoji)
}
