package com.friends.backend.reel.comment;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ReelCommentDislikeRepository extends JpaRepository<ReelCommentDislikeEntity, ReelCommentReactionId> {
  boolean existsById(ReelCommentReactionId id);

  @Query("select d.id.userId from ReelCommentDislikeEntity d where d.id.commentId = :commentId")
  List<Long> findUserIdsWhoDisliked(@Param("commentId") long commentId);
}
