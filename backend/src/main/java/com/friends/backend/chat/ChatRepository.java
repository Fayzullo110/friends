package com.friends.backend.chat;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ChatRepository extends JpaRepository<ChatEntity, Long> {
  @Query(value = "select c.* from chats c join chat_members m on m.chat_id = c.id where m.user_id = :userId order by c.updated_at desc limit 200", nativeQuery = true)
  List<ChatEntity> findMyChats(@Param("userId") long userId);
}
