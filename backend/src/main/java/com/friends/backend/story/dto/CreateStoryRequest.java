package com.friends.backend.story.dto;

import java.util.List;

public class CreateStoryRequest {
  public String mediaUrl;
  public String mediaType;
  public String text;
  public String musicTitle;
  public String musicArtist;
  public String musicUrl;
  public List<StoryStickerRequest> stickers;
}
