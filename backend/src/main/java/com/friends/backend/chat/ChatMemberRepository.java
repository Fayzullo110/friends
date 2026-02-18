package com.friends.backend.chat;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ChatMemberRepository extends JpaRepository<ChatMemberEntity, ChatMemberId> {
  boolean existsById(ChatMemberId id);

  @Query("select m.id.userId from ChatMemberEntity m where m.id.chatId = :chatId")
  List<Long> findMemberIds(@Param("chatId") long chatId);

  @Query("select m.id.chatId from ChatMemberEntity m where m.id.userId = :userId")
  List<Long> findChatIdsForUser(@Param("userId") long userId);
}
