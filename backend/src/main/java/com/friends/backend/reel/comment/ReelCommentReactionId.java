package com.friends.backend.reel.comment;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class ReelCommentReactionId implements Serializable {
  @Column(name = "comment_id")
  private Long commentId;

  @Column(name = "user_id")
  private Long userId;

  protected ReelCommentReactionId() {}

  public ReelCommentReactionId(Long commentId, Long userId) {
    this.commentId = commentId;
    this.userId = userId;
  }

  public Long getCommentId() { return commentId; }
  public Long getUserId() { return userId; }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    ReelCommentReactionId that = (ReelCommentReactionId) o;
    return Objects.equals(commentId, that.commentId) && Objects.equals(userId, that.userId);
  }

  @Override
  public int hashCode() { return Objects.hash(commentId, userId); }
}
