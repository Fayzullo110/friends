package com.friends.backend.block;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class UserBlockId implements Serializable {
  @Column(name = "blocker_id", nullable = false)
  private Long blockerId;

  @Column(name = "blocked_id", nullable = false)
  private Long blockedId;

  protected UserBlockId() {}

  public UserBlockId(Long blockerId, Long blockedId) {
    this.blockerId = blockerId;
    this.blockedId = blockedId;
  }

  public Long getBlockerId() {
    return blockerId;
  }

  public Long getBlockedId() {
    return blockedId;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    UserBlockId that = (UserBlockId) o;
    return Objects.equals(blockerId, that.blockerId) && Objects.equals(blockedId, that.blockedId);
  }

  @Override
  public int hashCode() {
    return Objects.hash(blockerId, blockedId);
  }
}
