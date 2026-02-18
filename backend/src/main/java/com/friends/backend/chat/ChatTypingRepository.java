package com.friends.backend.chat;

import java.time.Instant;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ChatTypingRepository extends JpaRepository<ChatTypingEntity, ChatTypingId> {
  @Query("select t from ChatTypingEntity t where t.id.chatId = :chatId and t.typing = true and t.updatedAt >= :cutoff")
  List<ChatTypingEntity> findActiveTyping(@Param("chatId") long chatId, @Param("cutoff") Instant cutoff);
}
