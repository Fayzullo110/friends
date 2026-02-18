package com.friends.backend.comment;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "comment_likes")
public class CommentLikeEntity {
  @EmbeddedId
  private CommentReactionId id;

  protected CommentLikeEntity() {}

  public CommentLikeEntity(CommentReactionId id) { this.id = id; }

  public CommentReactionId getId() { return id; }
}
