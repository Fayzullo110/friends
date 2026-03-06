package com.friends.backend.story.highlights;

import jakarta.persistence.*;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class StoryHighlightItemId implements Serializable {
  @Column(name = "highlight_id")
  private Long highlightId;

  @Column(name = "story_id")
  private Long storyId;

  public StoryHighlightItemId() {}

  public StoryHighlightItemId(Long highlightId, Long storyId) {
    this.highlightId = highlightId;
    this.storyId = storyId;
  }

  public Long getHighlightId() { return highlightId; }
  public Long getStoryId() { return storyId; }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof StoryHighlightItemId that)) return false;
    return Objects.equals(highlightId, that.highlightId) && Objects.equals(storyId, that.storyId);
  }

  @Override
  public int hashCode() {
    return Objects.hash(highlightId, storyId);
  }
}
