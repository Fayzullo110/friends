package com.friends.backend.chat;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ChatRepository extends JpaRepository<ChatEntity, Long> {
  @Query(value = "select c.* from chats c join chat_members m on m.chat_id = c.id where m.user_id = :userId order by c.updated_at desc limit 200", nativeQuery = true)
  List<ChatEntity> findMyChats(@Param("userId") long userId);

  @Query(
      value = "select count(*) from (" +
          " select c.id as chat_id" +
          " from chats c" +
          " join chat_members m on m.chat_id = c.id" +
          " join (select chat_id, max(id) as last_message_id from chat_messages group by chat_id) lm" +
          "   on lm.chat_id = c.id" +
          " join chat_messages msg on msg.id = lm.last_message_id" +
          " left join chat_message_seen seen" +
          "   on seen.message_id = msg.id and seen.user_id = :userId" +
          " where m.user_id = :userId" +
          "   and msg.sender_id <> :userId" +
          "   and seen.user_id is null" +
          " group by c.id" +
          ") t",
      nativeQuery = true)
  long unreadChatCount(@Param("userId") long userId);
}
