package com.friends.backend.status;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class UserStatusSeenId implements Serializable {
  @Column(name = "status_id")
  private Long statusId;

  @Column(name = "user_id")
  private Long userId;

  protected UserStatusSeenId() {}

  public UserStatusSeenId(Long statusId, Long userId) {
    this.statusId = statusId;
    this.userId = userId;
  }

  public Long getStatusId() { return statusId; }
  public Long getUserId() { return userId; }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    UserStatusSeenId that = (UserStatusSeenId) o;
    return Objects.equals(statusId, that.statusId) && Objects.equals(userId, that.userId);
  }

  @Override
  public int hashCode() { return Objects.hash(statusId, userId); }
}
