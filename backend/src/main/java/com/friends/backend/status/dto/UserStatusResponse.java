package com.friends.backend.status.dto;

import java.time.Instant;
import java.util.List;

public class UserStatusResponse {
  public long id;
  public long userId;
  public String username;
  public String photoUrl;
  public String text;
  public String emoji;
  public String musicTitle;
  public String musicArtist;
  public String musicUrl;
  public long createdAt;
  public long expiresAt;
  public List<Long> seenBy;

  public UserStatusResponse(
      long id,
      long userId,
      String username,
      String photoUrl,
      String text,
      String emoji,
      String musicTitle,
      String musicArtist,
      String musicUrl,
      Instant createdAt,
      Instant expiresAt,
      List<Long> seenBy) {
    this.id = id;
    this.userId = userId;
    this.username = username;
    this.photoUrl = photoUrl;
    this.text = text;
    this.emoji = emoji;
    this.musicTitle = musicTitle;
    this.musicArtist = musicArtist;
    this.musicUrl = musicUrl;
    this.createdAt = createdAt == null ? 0L : createdAt.toEpochMilli();
    this.expiresAt = expiresAt == null ? 0L : expiresAt.toEpochMilli();
    this.seenBy = seenBy;
  }
}
