package com.friends.backend.reel;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ReelLikeRepository extends JpaRepository<ReelLikeEntity, ReelLikeId> {
  boolean existsById(ReelLikeId id);

  @Query("select l.id.userId from ReelLikeEntity l where l.id.reelId = :reelId")
  List<Long> findUserIdsWhoLiked(@Param("reelId") long reelId);
}
