package com.friends.backend.story.highlights;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StoryHighlightRepository extends JpaRepository<StoryHighlightEntity, Long> {
  List<StoryHighlightEntity> findByOwnerIdOrderByUpdatedAtDesc(long ownerId);
}
