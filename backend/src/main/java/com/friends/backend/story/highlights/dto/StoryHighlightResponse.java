package com.friends.backend.story.highlights.dto;

import java.util.List;

public class StoryHighlightResponse {
  public long id;
  public long ownerId;
  public String title;
  public long updatedAt;

  public Integer itemCount;
  public Long coverStoryId;
  public String coverMediaType;
  public String coverMediaUrl;

  public List<Long> storyIds;

  public StoryHighlightResponse(
      long id,
      long ownerId,
      String title,
      long updatedAt,
      Integer itemCount,
      Long coverStoryId,
      String coverMediaType,
      String coverMediaUrl,
      List<Long> storyIds) {
    this.id = id;
    this.ownerId = ownerId;
    this.title = title;
    this.updatedAt = updatedAt;
    this.itemCount = itemCount;
    this.coverStoryId = coverStoryId;
    this.coverMediaType = coverMediaType;
    this.coverMediaUrl = coverMediaUrl;
    this.storyIds = storyIds;
  }
}
