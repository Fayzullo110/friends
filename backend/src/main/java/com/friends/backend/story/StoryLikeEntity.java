package com.friends.backend.story;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "story_likes")
public class StoryLikeEntity {
  @EmbeddedId
  private StoryLikeId id;

  protected StoryLikeEntity() {}

  public StoryLikeEntity(StoryLikeId id) { this.id = id; }

  public StoryLikeId getId() { return id; }
}
