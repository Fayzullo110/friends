package com.friends.backend.status;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserStatusSeenRepository extends JpaRepository<UserStatusSeenEntity, UserStatusSeenId> {
  boolean existsById(UserStatusSeenId id);

  @Query("select s.id.userId from UserStatusSeenEntity s where s.id.statusId = :statusId")
  List<Long> findUserIdsWhoSaw(@Param("statusId") long statusId);
}
