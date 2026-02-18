package com.friends.backend.reel.comment;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "reel_comment_likes")
public class ReelCommentLikeEntity {
  @EmbeddedId
  private ReelCommentReactionId id;

  protected ReelCommentLikeEntity() {}

  public ReelCommentLikeEntity(ReelCommentReactionId id) { this.id = id; }

  public ReelCommentReactionId getId() { return id; }
}
