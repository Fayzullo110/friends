package com.friends.backend.mute;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserMuteRepository extends JpaRepository<UserMuteEntity, UserMuteId> {
  boolean existsById(UserMuteId id);

  @Query("select m.id.mutedId from UserMuteEntity m where m.id.muterId = :muterId")
  List<Long> findMutedIds(@Param("muterId") long muterId);
}
