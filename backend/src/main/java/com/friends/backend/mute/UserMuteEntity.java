package com.friends.backend.mute;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.time.Instant;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "user_mutes")
public class UserMuteEntity {
  @EmbeddedId
  private UserMuteId id;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  protected UserMuteEntity() {}

  public UserMuteEntity(UserMuteId id) {
    this.id = id;
  }

  public UserMuteId getId() { return id; }
  public Instant getCreatedAt() { return createdAt; }
}
