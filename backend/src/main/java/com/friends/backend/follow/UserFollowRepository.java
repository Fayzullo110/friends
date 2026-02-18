package com.friends.backend.follow;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserFollowRepository extends JpaRepository<UserFollowEntity, UserFollowId> {
  boolean existsById(UserFollowId id);

  @Query("select f.id.followerId from UserFollowEntity f where f.id.followingId = :userId")
  List<Long> findFollowerIds(@Param("userId") long userId);

  @Query("select f.id.followingId from UserFollowEntity f where f.id.followerId = :userId")
  List<Long> findFollowingIds(@Param("userId") long userId);
}
