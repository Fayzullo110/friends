package com.friends.backend.friend;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FriendRepository extends JpaRepository<FriendEntity, FriendId> {
  @Query("select f.id.friendUserId from FriendEntity f where f.id.userId = :userId")
  List<Long> findFriendIds(@Param("userId") long userId);

  @Query("select f.id.friendUserId from FriendEntity f where f.id.userId in :userIds")
  List<Long> findFriendIdsForUsers(@Param("userIds") List<Long> userIds);

  boolean existsById(FriendId id);
}
