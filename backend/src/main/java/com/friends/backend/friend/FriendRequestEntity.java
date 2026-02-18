package com.friends.backend.friend;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "friend_requests")
public class FriendRequestEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "from_user_id", nullable = false)
  private Long fromUserId;

  @Column(name = "to_user_id", nullable = false)
  private Long toUserId;

  @Column(name = "status", nullable = false)
  private String status = "pending";

  @Column(name = "created_at", nullable = false)
  private Instant createdAt = Instant.now();

  public Long getId() {
    return id;
  }

  public Long getFromUserId() {
    return fromUserId;
  }

  public void setFromUserId(Long fromUserId) {
    this.fromUserId = fromUserId;
  }

  public Long getToUserId() {
    return toUserId;
  }

  public void setToUserId(Long toUserId) {
    this.toUserId = toUserId;
  }

  public String getStatus() {
    return status;
  }

  public void setStatus(String status) {
    this.status = status;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public void setCreatedAt(Instant createdAt) {
    this.createdAt = createdAt;
  }
}
