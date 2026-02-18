package com.friends.backend.friend;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "friends")
public class FriendEntity {
  @EmbeddedId
  private FriendId id;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt = Instant.now();

  public FriendEntity() {}

  public FriendEntity(FriendId id) {
    this.id = id;
  }

  public FriendId getId() {
    return id;
  }

  public void setId(FriendId id) {
    this.id = id;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public void setCreatedAt(Instant createdAt) {
    this.createdAt = createdAt;
  }
}
