package com.friends.backend.closefriends;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "close_friends")
public class CloseFriendEntity {
  @EmbeddedId
  private CloseFriendId id;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt = Instant.now();

  public CloseFriendEntity() {}

  public CloseFriendEntity(CloseFriendId id) {
    this.id = id;
  }

  public CloseFriendId getId() {
    return id;
  }

  public void setId(CloseFriendId id) {
    this.id = id;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public void setCreatedAt(Instant createdAt) {
    this.createdAt = createdAt;
  }
}
