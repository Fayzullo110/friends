package com.friends.backend.story;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class StoryLikeId implements Serializable {
  @Column(name = "story_id")
  private Long storyId;

  @Column(name = "user_id")
  private Long userId;

  protected StoryLikeId() {}

  public StoryLikeId(Long storyId, Long userId) {
    this.storyId = storyId;
    this.userId = userId;
  }

  public Long getStoryId() { return storyId; }
  public Long getUserId() { return userId; }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    StoryLikeId that = (StoryLikeId) o;
    return Objects.equals(storyId, that.storyId) && Objects.equals(userId, that.userId);
  }

  @Override
  public int hashCode() { return Objects.hash(storyId, userId); }
}
