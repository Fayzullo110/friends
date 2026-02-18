package com.friends.backend.post;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PostLikeRepository extends JpaRepository<PostLikeEntity, PostLikeId> {
  boolean existsById(PostLikeId id);

  @Query("select l.id.userId from PostLikeEntity l where l.id.postId = :postId")
  List<Long> findUserIdsWhoLiked(@Param("postId") long postId);
}
