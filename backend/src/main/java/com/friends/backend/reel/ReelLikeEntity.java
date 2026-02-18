package com.friends.backend.reel;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "reel_likes")
public class ReelLikeEntity {
  @EmbeddedId
  private ReelLikeId id;

  protected ReelLikeEntity() {}

  public ReelLikeEntity(ReelLikeId id) { this.id = id; }

  public ReelLikeId getId() { return id; }
}
