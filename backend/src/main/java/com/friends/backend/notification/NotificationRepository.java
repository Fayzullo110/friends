package com.friends.backend.notification;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

public interface NotificationRepository extends JpaRepository<NotificationEntity, Long> {
  List<NotificationEntity> findTop50ByToUserIdOrderByCreatedAtDesc(long toUserId);

  List<NotificationEntity> findTop50ByToUserIdAndIsReadFalseOrderByCreatedAtDesc(long toUserId);

  @Transactional
  @Modifying
  @Query("update NotificationEntity n set n.isRead = true where n.toUserId = :toUserId and n.isRead = false")
  int markAllAsRead(@Param("toUserId") long toUserId);
}
