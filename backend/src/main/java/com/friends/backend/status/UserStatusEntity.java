package com.friends.backend.status;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "user_statuses")
public class UserStatusEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "user_id", nullable = false)
  private Long userId;

  @Column(nullable = false, columnDefinition = "TEXT")
  private String text;

  @Column
  private String emoji;

  @Column(name = "music_title")
  private String musicTitle;

  @Column(name = "music_artist")
  private String musicArtist;

  @Column(name = "music_url", columnDefinition = "TEXT")
  private String musicUrl;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "expires_at", nullable = false)
  private Instant expiresAt;

  @PrePersist
  void onCreate() { if (createdAt == null) createdAt = Instant.now(); }

  public Long getId() { return id; }
  public Long getUserId() { return userId; }
  public void setUserId(Long userId) { this.userId = userId; }
  public String getText() { return text; }
  public void setText(String text) { this.text = text; }
  public String getEmoji() { return emoji; }
  public void setEmoji(String emoji) { this.emoji = emoji; }
  public String getMusicTitle() { return musicTitle; }
  public void setMusicTitle(String musicTitle) { this.musicTitle = musicTitle; }
  public String getMusicArtist() { return musicArtist; }
  public void setMusicArtist(String musicArtist) { this.musicArtist = musicArtist; }
  public String getMusicUrl() { return musicUrl; }
  public void setMusicUrl(String musicUrl) { this.musicUrl = musicUrl; }
  public Instant getCreatedAt() { return createdAt; }
  public Instant getExpiresAt() { return expiresAt; }
  public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }
}
