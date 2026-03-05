package com.friends.backend.post;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;

public interface PostRepository extends JpaRepository<PostEntity, Long> {
  List<PostEntity> findTop100ByArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc();

  List<PostEntity> findByArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(Pageable pageable);

  List<PostEntity> findByAuthorIdAndArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(long authorId, Pageable pageable);

  List<PostEntity> findTop200ByAuthorIdAndArchivedAtIsNotNullAndDeletedAtIsNullOrderByArchivedAtDesc(long authorId);

  long countByAuthorIdAndArchivedAtIsNullAndDeletedAtIsNull(long authorId);
}
