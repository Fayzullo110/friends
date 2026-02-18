package com.friends.backend.chat;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ChatMessageReactionRepository extends JpaRepository<ChatMessageReactionEntity, ChatMessageReactionId> {
  boolean existsById(ChatMessageReactionId id);

  @Query("select r.id.emoji, r.id.userId from ChatMessageReactionEntity r where r.id.messageId = :messageId")
  List<Object[]> findEmojiAndUserId(@Param("messageId") long messageId);
}
