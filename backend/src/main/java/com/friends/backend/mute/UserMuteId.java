package com.friends.backend.mute;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class UserMuteId implements Serializable {
  @Column(name = "muter_id", nullable = false)
  private Long muterId;

  @Column(name = "muted_id", nullable = false)
  private Long mutedId;

  protected UserMuteId() {}

  public UserMuteId(Long muterId, Long mutedId) {
    this.muterId = muterId;
    this.mutedId = mutedId;
  }

  public Long getMuterId() { return muterId; }
  public Long getMutedId() { return mutedId; }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    UserMuteId that = (UserMuteId) o;
    return Objects.equals(muterId, that.muterId) && Objects.equals(mutedId, that.mutedId);
  }

  @Override
  public int hashCode() {
    return Objects.hash(muterId, mutedId);
  }
}
