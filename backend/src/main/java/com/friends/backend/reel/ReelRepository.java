package com.friends.backend.reel;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReelRepository extends JpaRepository<ReelEntity, Long> {
  List<ReelEntity> findTop100ByArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc();

  List<ReelEntity> findTop100ByAuthorIdAndArchivedAtIsNotNullAndDeletedAtIsNullOrderByArchivedAtDescCreatedAtDesc(
      Long authorId);
}
