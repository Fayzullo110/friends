package com.friends.backend.comment;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CommentDislikeRepository extends JpaRepository<CommentDislikeEntity, CommentReactionId> {
  boolean existsById(CommentReactionId id);

  @Query("select d.id.userId from CommentDislikeEntity d where d.id.commentId = :commentId")
  List<Long> findUserIdsWhoDisliked(@Param("commentId") long commentId);
}
