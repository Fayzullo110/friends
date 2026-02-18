package com.friends.backend.post;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PostRepository extends JpaRepository<PostEntity, Long> {
  List<PostEntity> findTop100ByArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc();

  List<PostEntity> findTop200ByAuthorIdAndArchivedAtIsNotNullAndDeletedAtIsNullOrderByArchivedAtDesc(long authorId);
}
