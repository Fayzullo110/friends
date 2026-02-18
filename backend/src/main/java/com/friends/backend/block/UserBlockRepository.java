package com.friends.backend.block;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserBlockRepository extends JpaRepository<UserBlockEntity, UserBlockId> {
  boolean existsById(UserBlockId id);

  @Query("select b.id.blockedId from UserBlockEntity b where b.id.blockerId = :blockerId")
  List<Long> findBlockedIds(@Param("blockerId") long blockerId);

  @Query("select b.id.blockerId from UserBlockEntity b where b.id.blockedId = :blockedId")
  List<Long> findBlockerIds(@Param("blockedId") long blockedId);
}
