package com.friends.backend.chat;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ChatMessageSeenRepository extends JpaRepository<ChatMessageSeenEntity, ChatMessageSeenId> {
  boolean existsById(ChatMessageSeenId id);

  @Query("select s.id.userId from ChatMessageSeenEntity s where s.id.messageId = :messageId")
  List<Long> findUserIdsWhoSaw(@Param("messageId") long messageId);
}
