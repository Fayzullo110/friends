package com.friends.backend.notification;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "notifications")
public class NotificationEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "to_user_id", nullable = false)
  private Long toUserId;

  @Column(name = "from_user_id", nullable = false)
  private Long fromUserId;

  @Column(name = "type", nullable = false)
  private String type;

  @Column(name = "post_id")
  private Long postId;

  @Column(name = "is_read", nullable = false)
  private Boolean isRead = false;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt = Instant.now();

  public Long getId() {
    return id;
  }

  public Long getToUserId() {
    return toUserId;
  }

  public void setToUserId(Long toUserId) {
    this.toUserId = toUserId;
  }

  public Long getFromUserId() {
    return fromUserId;
  }

  public void setFromUserId(Long fromUserId) {
    this.fromUserId = fromUserId;
  }

  public String getType() {
    return type;
  }

  public void setType(String type) {
    this.type = type;
  }

  public Long getPostId() {
    return postId;
  }

  public void setPostId(Long postId) {
    this.postId = postId;
  }

  public Boolean getIsRead() {
    return isRead;
  }

  public void setIsRead(Boolean isRead) {
    this.isRead = isRead;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public void setCreatedAt(Instant createdAt) {
    this.createdAt = createdAt;
  }
}
