package com.friends.backend.status;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "user_status_seen")
public class UserStatusSeenEntity {
  @EmbeddedId
  private UserStatusSeenId id;

  protected UserStatusSeenEntity() {}

  public UserStatusSeenEntity(UserStatusSeenId id) { this.id = id; }

  public UserStatusSeenId getId() { return id; }
}
