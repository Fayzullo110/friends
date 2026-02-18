package com.friends.backend.reel.comment;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ReelCommentLikeRepository extends JpaRepository<ReelCommentLikeEntity, ReelCommentReactionId> {
  boolean existsById(ReelCommentReactionId id);

  @Query("select l.id.userId from ReelCommentLikeEntity l where l.id.commentId = :commentId")
  List<Long> findUserIdsWhoLiked(@Param("commentId") long commentId);
}
