package com.friends.backend.reel.comment;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReelCommentRepository extends JpaRepository<ReelCommentEntity, Long> {
  List<ReelCommentEntity> findByReelIdOrderByCreatedAtAsc(long reelId);
}
