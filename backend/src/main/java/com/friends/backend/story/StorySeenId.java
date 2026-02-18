package com.friends.backend.story;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class StorySeenId implements Serializable {
  @Column(name = "story_id")
  private Long storyId;

  @Column(name = "user_id")
  private Long userId;

  protected StorySeenId() {}

  public StorySeenId(Long storyId, Long userId) {
    this.storyId = storyId;
    this.userId = userId;
  }

  public Long getStoryId() { return storyId; }
  public Long getUserId() { return userId; }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    StorySeenId that = (StorySeenId) o;
    return Objects.equals(storyId, that.storyId) && Objects.equals(userId, that.userId);
  }

  @Override
  public int hashCode() { return Objects.hash(storyId, userId); }
}
