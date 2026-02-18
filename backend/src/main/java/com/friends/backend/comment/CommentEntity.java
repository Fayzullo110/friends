package com.friends.backend.comment;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "comments")
public class CommentEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "post_id", nullable = false)
  private Long postId;

  @Column(name = "author_id", nullable = false)
  private Long authorId;

  @Column(nullable = false, columnDefinition = "TEXT")
  private String text;

  @Column(nullable = false)
  private String type;

  @Column(name = "media_url", columnDefinition = "TEXT")
  private String mediaUrl;

  @Column(name = "parent_comment_id")
  private Long parentCommentId;

  @Column(name = "like_count", nullable = false)
  private int likeCount;

  @Column(name = "dislike_count", nullable = false)
  private int dislikeCount;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @PrePersist
  void onCreate() { if (createdAt == null) createdAt = Instant.now(); }

  public Long getId() { return id; }
  public Long getPostId() { return postId; }
  public void setPostId(Long postId) { this.postId = postId; }
  public Long getAuthorId() { return authorId; }
  public void setAuthorId(Long authorId) { this.authorId = authorId; }
  public String getText() { return text; }
  public void setText(String text) { this.text = text; }
  public String getType() { return type; }
  public void setType(String type) { this.type = type; }
  public String getMediaUrl() { return mediaUrl; }
  public void setMediaUrl(String mediaUrl) { this.mediaUrl = mediaUrl; }
  public Long getParentCommentId() { return parentCommentId; }
  public void setParentCommentId(Long parentCommentId) { this.parentCommentId = parentCommentId; }
  public int getLikeCount() { return likeCount; }
  public void setLikeCount(int likeCount) { this.likeCount = likeCount; }
  public int getDislikeCount() { return dislikeCount; }
  public void setDislikeCount(int dislikeCount) { this.dislikeCount = dislikeCount; }
  public Instant getCreatedAt() { return createdAt; }
}
