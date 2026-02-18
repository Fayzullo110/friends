package com.friends.backend.story.comment;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StoryCommentRepository extends JpaRepository<StoryCommentEntity, Long> {
  List<StoryCommentEntity> findByStoryIdOrderByCreatedAtDesc(long storyId);
}
