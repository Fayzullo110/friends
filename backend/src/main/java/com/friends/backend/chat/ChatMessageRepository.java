package com.friends.backend.chat;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ChatMessageRepository extends JpaRepository<ChatMessageEntity, Long> {
  @Query(
      value = "select * from chat_messages where chat_id = :chatId order by created_at desc limit :limit offset :offset",
      nativeQuery = true)
  List<ChatMessageEntity> findRecent(
      @Param("chatId") long chatId,
      @Param("limit") int limit,
      @Param("offset") int offset);
}
