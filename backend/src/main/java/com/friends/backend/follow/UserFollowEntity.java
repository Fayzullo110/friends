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

  protected UserFollowEntity() {}

  public UserFollowEntity(UserFollowId id) {
    this.id = id;
  }

  public UserFollowId getId() {
    return id;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
