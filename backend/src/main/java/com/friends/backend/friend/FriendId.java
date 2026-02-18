package com.friends.backend.friend;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class FriendId implements Serializable {
  @Column(name = "user_id")
  public Long userId;

  @Column(name = "friend_user_id")
  public Long friendUserId;

  public FriendId() {}

  public FriendId(Long userId, Long friendUserId) {
    this.userId = userId;
    this.friendUserId = friendUserId;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    FriendId that = (FriendId) o;
    return Objects.equals(userId, that.userId) && Objects.equals(friendUserId, that.friendUserId);
  }

  @Override
  public int hashCode() {
    return Objects.hash(userId, friendUserId);
  }
}
