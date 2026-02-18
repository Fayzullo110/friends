package com.friends.backend.story;

import java.time.Instant;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StoryRepository extends JpaRepository<StoryEntity, Long> {
  List<StoryEntity> findTop200ByExpiresAtAfterOrderByExpiresAtAscCreatedAtDesc(Instant now);
  List<StoryEntity> findTop200ByAuthorIdAndExpiresAtAfterOrderByExpiresAtAscCreatedAtDesc(long authorId, Instant now);
}
