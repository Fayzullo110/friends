package com.friends.backend.story;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

@Entity
@Table(name = "story_seen")
public class StorySeenEntity {
  @EmbeddedId
  private StorySeenId id;

  protected StorySeenEntity() {}

  public StorySeenEntity(StorySeenId id) { this.id = id; }

  public StorySeenId getId() { return id; }
}
