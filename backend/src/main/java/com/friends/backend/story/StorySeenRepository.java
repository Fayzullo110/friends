package com.friends.backend.story;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface StorySeenRepository extends JpaRepository<StorySeenEntity, StorySeenId> {
  boolean existsById(StorySeenId id);

  @Query("select s.id.userId from StorySeenEntity s where s.id.storyId = :storyId")
  List<Long> findUserIdsWhoSaw(@Param("storyId") long storyId);
}
