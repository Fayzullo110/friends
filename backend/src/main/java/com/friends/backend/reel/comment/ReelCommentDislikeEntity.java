package com.friends.backend.reel.comment;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "reel_comment_dislikes")
public class ReelCommentDislikeEntity {
  @EmbeddedId
  private ReelCommentReactionId id;

  protected ReelCommentDislikeEntity() {}

  public ReelCommentDislikeEntity(ReelCommentReactionId id) { this.id = id; }

  public ReelCommentReactionId getId() { return id; }
}
