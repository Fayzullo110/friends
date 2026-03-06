package com.friends.backend.follow;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserFollowRepository extends JpaRepository<UserFollowEntity, UserFollowId> {
  boolean existsById(UserFollowId id);

  @Query("select (count(f) > 0) from UserFollowEntity f where f.id.followerId = :followerId and f.id.followingId = :followingId and f.status = 'accepted'")
  boolean existsAccepted(@Param("followerId") long followerId, @Param("followingId") long followingId);

  @Query("select f.id.followerId from UserFollowEntity f where f.id.followingId = :userId and f.status = 'accepted'")
  List<Long> findFollowerIds(@Param("userId") long userId);

  @Query("select f.id.followingId from UserFollowEntity f where f.id.followerId = :userId and f.status = 'accepted'")
  List<Long> findFollowingIds(@Param("userId") long userId);

  @Query("select f.id.followerId from UserFollowEntity f where f.id.followingId = :userId and f.status = 'pending'")
  List<Long> findIncomingRequestFollowerIds(@Param("userId") long userId);

  @Query("select f.id.followingId from UserFollowEntity f where f.id.followerId = :userId and f.status = 'pending'")
  List<Long> findOutgoingRequestFollowingIds(@Param("userId") long userId);
}
