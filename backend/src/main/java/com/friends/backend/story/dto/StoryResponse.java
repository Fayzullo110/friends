package com.friends.backend.story.dto;

import java.time.Instant;
import java.util.List;

public class StoryResponse {
  public long id;
  public long authorId;
  public String authorUsername;
  public String authorThemeKey;
  public Integer authorThemeSeedColor;
  public String mediaUrl;
  public String mediaType;
  public String text;
  public long createdAt;
  public long expiresAt;
  public List<Long> seenBy;
  public List<Long> likedBy;
  public String musicTitle;
  public String musicArtist;
  public String musicUrl;

  public StoryResponse(
      long id,
      long authorId,
      String authorUsername,
      String authorThemeKey,
      Integer authorThemeSeedColor,
      String mediaUrl,
      String mediaType,
      String text,
      Instant createdAt,
      Instant expiresAt,
      List<Long> seenBy,
      List<Long> likedBy,
      String musicTitle,
      String musicArtist,
      String musicUrl) {
    this.id = id;
    this.authorId = authorId;
    this.authorUsername = authorUsername;
    this.authorThemeKey = authorThemeKey;
    this.authorThemeSeedColor = authorThemeSeedColor;
    this.mediaUrl = mediaUrl;
    this.mediaType = mediaType;
    this.text = text;
    this.createdAt = createdAt == null ? 0L : createdAt.toEpochMilli();
    this.expiresAt = expiresAt == null ? 0L : expiresAt.toEpochMilli();
    this.seenBy = seenBy;
    this.likedBy = likedBy;
    this.musicTitle = musicTitle;
    this.musicArtist = musicArtist;
    this.musicUrl = musicUrl;
  }
}
