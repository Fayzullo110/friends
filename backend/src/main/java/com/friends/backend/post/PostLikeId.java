package com.friends.backend.post;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class PostLikeId implements Serializable {
  @Column(name = "post_id")
  private Long postId;

  @Column(name = "user_id")
  private Long userId;

  protected PostLikeId() {}

  public PostLikeId(Long postId, Long userId) {
    this.postId = postId;
    this.userId = userId;
  }

  public Long getPostId() { return postId; }
  public Long getUserId() { return userId; }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    PostLikeId that = (PostLikeId) o;
    return Objects.equals(postId, that.postId) && Objects.equals(userId, that.userId);
  }

  @Override
  public int hashCode() {
    return Objects.hash(postId, userId);
  }
}
