package com.friends.backend.friend;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FriendRequestRepository extends JpaRepository<FriendRequestEntity, Long> {
  boolean existsByFromUserIdAndToUserIdAndStatus(long fromUserId, long toUserId, String status);

  List<FriendRequestEntity> findTop50ByToUserIdAndStatusOrderByCreatedAtDesc(long toUserId, String status);

  List<FriendRequestEntity> findTop50ByFromUserIdAndStatusOrderByCreatedAtDesc(long fromUserId, String status);
}
