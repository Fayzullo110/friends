package com.friends.backend.reel;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;

public interface ReelRepository extends JpaRepository<ReelEntity, Long> {
  List<ReelEntity> findTop100ByArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc();

  List<ReelEntity> findByArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(Pageable pageable);

  List<ReelEntity> findTop100ByAuthorIdAndArchivedAtIsNotNullAndDeletedAtIsNullOrderByArchivedAtDescCreatedAtDesc(
      Long authorId);
}
