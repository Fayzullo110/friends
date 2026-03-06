package com.friends.backend.closefriends;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CloseFriendRepository extends JpaRepository<CloseFriendEntity, CloseFriendId> {
  @Query("select c.id.closeFriendUserId from CloseFriendEntity c where c.id.userId = :userId")
  List<Long> findCloseFriendIds(@Param("userId") long userId);
}
