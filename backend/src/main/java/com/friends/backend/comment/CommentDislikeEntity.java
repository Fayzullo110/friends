package com.friends.backend.comment;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "comment_dislikes")
public class CommentDislikeEntity {
  @EmbeddedId
  private CommentReactionId id;

  protected CommentDislikeEntity() {}

  public CommentDislikeEntity(CommentReactionId id) { this.id = id; }

  public CommentReactionId getId() { return id; }
}
