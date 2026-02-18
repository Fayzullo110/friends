package com.friends.backend.story;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface StoryLikeRepository extends JpaRepository<StoryLikeEntity, StoryLikeId> {
  boolean existsById(StoryLikeId id);

  @Query("select l.id.userId from StoryLikeEntity l where l.id.storyId = :storyId")
  List<Long> findUserIdsWhoLiked(@Param("storyId") long storyId);
}
