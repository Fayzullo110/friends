package com.friends.backend.reel;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class ReelLikeId implements Serializable {
  @Column(name = "reel_id")
  private Long reelId;

  @Column(name = "user_id")
  private Long userId;

  protected ReelLikeId() {}

  public ReelLikeId(Long reelId, Long userId) {
    this.reelId = reelId;
    this.userId = userId;
  }

  public Long getReelId() { return reelId; }
  public Long getUserId() { return userId; }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    ReelLikeId that = (ReelLikeId) o;
    return Objects.equals(reelId, that.reelId) && Objects.equals(userId, that.userId);
  }

  @Override
  public int hashCode() { return Objects.hash(reelId, userId); }
}
