package com.friends.backend.status;

import java.time.Instant;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserStatusRepository extends JpaRepository<UserStatusEntity, Long> {
  List<UserStatusEntity> findTop200ByExpiresAtAfterOrderByExpiresAtAscCreatedAtDesc(Instant now);
  List<UserStatusEntity> findTop1ByUserIdAndExpiresAtAfterOrderByExpiresAtAscCreatedAtDesc(long userId, Instant now);
}
