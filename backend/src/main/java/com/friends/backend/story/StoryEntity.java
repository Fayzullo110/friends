package com.friends.backend.story;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "stories")
public class StoryEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "author_id", nullable = false)
  private Long authorId;

  @Column(name = "media_url", columnDefinition = "TEXT")
  private String mediaUrl;

  @Column(name = "media_type", nullable = false)
  private String mediaType;

  @Column(columnDefinition = "TEXT")
  private String text;

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
  void onCreate() {
    if (createdAt == null) createdAt = Instant.now();
  }

  public Long getId() { return id; }
  public Long getAuthorId() { return authorId; }
  public void setAuthorId(Long authorId) { this.authorId = authorId; }
  public String getMediaUrl() { return mediaUrl; }
  public void setMediaUrl(String mediaUrl) { this.mediaUrl = mediaUrl; }
  public String getMediaType() { return mediaType; }
  public void setMediaType(String mediaType) { this.mediaType = mediaType; }
  public String getText() { return text; }
  public void setText(String text) { this.text = text; }
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
