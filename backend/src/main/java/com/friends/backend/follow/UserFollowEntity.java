package com.friends.backend.follow;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Column;
import jakarta.persistence.Table;
import java.time.Instant;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "user_follows")
public class UserFollowEntity {
  @EmbeddedId
  private UserFollowId id;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "status", nullable = false, length = 20)
  private String status = "accepted";

  protected UserFollowEntity() {}

  public UserFollowEntity(UserFollowId id) {
    this.id = id;
  }

  public UserFollowEntity(UserFollowId id, String status) {
    this.id = id;
    this.status = status;
  }

  public UserFollowId getId() {
    return id;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public String getStatus() {
    return status;
  }

  public void setStatus(String status) {
    this.status = status;
  }
}
