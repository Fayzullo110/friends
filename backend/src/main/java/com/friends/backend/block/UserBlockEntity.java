package com.friends.backend.block;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Column;
import jakarta.persistence.Table;
import java.time.Instant;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "user_blocks")
public class UserBlockEntity {
  @EmbeddedId
  private UserBlockId id;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  protected UserBlockEntity() {}

  public UserBlockEntity(UserBlockId id) {
    this.id = id;
  }

  public UserBlockId getId() {
    return id;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
