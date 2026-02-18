package com.friends.backend.comment;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CommentLikeRepository extends JpaRepository<CommentLikeEntity, CommentReactionId> {
  boolean existsById(CommentReactionId id);

  @Query("select l.id.userId from CommentLikeEntity l where l.id.commentId = :commentId")
  List<Long> findUserIdsWhoLiked(@Param("commentId") long commentId);
}
