package com.friends.backend.story.highlights;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StoryHighlightItemRepository extends JpaRepository<StoryHighlightItemEntity, StoryHighlightItemId> {
  List<StoryHighlightItemEntity> findByIdHighlightIdOrderByPositionAsc(long highlightId);
  List<StoryHighlightItemEntity> findByIdHighlightIdInOrderByIdHighlightIdAscPositionAsc(List<Long> highlightIds);
}
