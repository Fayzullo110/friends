package com.friends.backend.closefriends;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class CloseFriendId implements Serializable {
  @Column(name = "user_id")
  public Long userId;

  @Column(name = "close_friend_user_id")
  public Long closeFriendUserId;

  public CloseFriendId() {}

  public CloseFriendId(Long userId, Long closeFriendUserId) {
    this.userId = userId;
    this.closeFriendUserId = closeFriendUserId;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    final CloseFriendId that = (CloseFriendId) o;
    return Objects.equals(userId, that.userId)
        && Objects.equals(closeFriendUserId, that.closeFriendUserId);
  }

  @Override
  public int hashCode() {
    return Objects.hash(userId, closeFriendUserId);
  }
}
