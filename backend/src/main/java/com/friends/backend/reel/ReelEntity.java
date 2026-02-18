package com.friends.backend.reel;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "reels")
public class ReelEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "author_id", nullable = false)
  private Long authorId;

  @Column(nullable = false, columnDefinition = "TEXT")
  private String caption;

  @Column(name = "media_url", columnDefinition = "TEXT")
  private String mediaUrl;

  @Column(name = "media_type", nullable = false)
  private String mediaType;

  @Column(name = "like_count", nullable = false)
  private int likeCount;

  @Column(name = "comment_count", nullable = false)
  private int commentCount;

  @Column(name = "share_count", nullable = false)
  private int shareCount;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "archived_at")
  private Instant archivedAt;

  @Column(name = "deleted_at")
  private Instant deletedAt;

  @PrePersist
  void onCreate() { if (createdAt == null) createdAt = Instant.now(); }

  public Long getId() { return id; }
  public Long getAuthorId() { return authorId; }
  public void setAuthorId(Long authorId) { this.authorId = authorId; }
  public String getCaption() { return caption; }
  public void setCaption(String caption) { this.caption = caption; }
  public String getMediaUrl() { return mediaUrl; }
  public void setMediaUrl(String mediaUrl) { this.mediaUrl = mediaUrl; }
  public String getMediaType() { return mediaType; }
  public void setMediaType(String mediaType) { this.mediaType = mediaType; }
  public int getLikeCount() { return likeCount; }
  public void setLikeCount(int likeCount) { this.likeCount = likeCount; }
  public int getCommentCount() { return commentCount; }
  public void setCommentCount(int commentCount) { this.commentCount = commentCount; }
  public int getShareCount() { return shareCount; }
  public void setShareCount(int shareCount) { this.shareCount = shareCount; }
  public Instant getCreatedAt() { return createdAt; }

  public Instant getArchivedAt() { return archivedAt; }
  public void setArchivedAt(Instant archivedAt) { this.archivedAt = archivedAt; }

  public Instant getDeletedAt() { return deletedAt; }
  public void setDeletedAt(Instant deletedAt) { this.deletedAt = deletedAt; }
}
