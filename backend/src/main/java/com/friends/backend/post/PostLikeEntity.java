package com.friends.backend.post;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "post_likes")
public class PostLikeEntity {
  @EmbeddedId
  private PostLikeId id;

  protected PostLikeEntity() {}

  public PostLikeEntity(PostLikeId id) {
    this.id = id;
  }

  public PostLikeId getId() { return id; }
}
