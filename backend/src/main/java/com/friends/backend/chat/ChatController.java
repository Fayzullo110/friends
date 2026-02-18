package com.friends.backend.chat;

import com.friends.backend.chat.dto.ChatMessageResponse;
import com.friends.backend.chat.dto.ChatResponse;
import com.friends.backend.chat.dto.CreateGroupChatRequest;
import com.friends.backend.chat.dto.MarkSeenRequest;
import com.friends.backend.chat.dto.SendMessageRequest;
import com.friends.backend.chat.dto.TypingUpdateRequest;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.*;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/chats")
public class ChatController {
  private final ChatRepository chatRepository;
  private final ChatMemberRepository chatMemberRepository;
  private final ChatMessageRepository chatMessageRepository;
  private final ChatMessageSeenRepository chatMessageSeenRepository;
  private final ChatMessageReactionRepository chatMessageReactionRepository;
  private final ChatTypingRepository chatTypingRepository;
  private final UserRepository userRepository;

  public ChatController(
      ChatRepository chatRepository,
      ChatMemberRepository chatMemberRepository,
      ChatMessageRepository chatMessageRepository,
      ChatMessageSeenRepository chatMessageSeenRepository,
      ChatMessageReactionRepository chatMessageReactionRepository,
      ChatTypingRepository chatTypingRepository,
      UserRepository userRepository) {
    this.chatRepository = chatRepository;
    this.chatMemberRepository = chatMemberRepository;
    this.chatMessageRepository = chatMessageRepository;
    this.chatMessageSeenRepository = chatMessageSeenRepository;
    this.chatMessageReactionRepository = chatMessageReactionRepository;
    this.chatTypingRepository = chatTypingRepository;
    this.userRepository = userRepository;
  }

  @GetMapping
  public List<ChatResponse> myChats(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return chatRepository.findMyChats(principal.getUserId()).stream().map(this::toChatResponse).toList();
  }

  @PostMapping("/direct/{otherUserId}")
  public ChatResponse createOrGetDirect(@PathVariable long otherUserId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final long me = principal.getUserId();

    if (me == otherUserId) {
      throw new IllegalArgumentException("Cannot direct-message yourself");
    }

    // Find existing direct chat by scanning my chats and checking member set.
    for (final ChatEntity c : chatRepository.findMyChats(me)) {
      if (c.isGroup()) continue;
      final List<Long> members = chatMemberRepository.findMemberIds(c.getId());
      if (members.size() == 2 && members.contains(me) && members.contains(otherUserId)) {
        return toChatResponse(c);
      }
    }

    // Create new chat.
    final ChatEntity chat = new ChatEntity();
    chat.setGroup(false);
    chat.setTitle(null);
    chat.setLastMessage("");
    chat.setUpdatedAt(Instant.now());
    final ChatEntity saved = chatRepository.save(chat);

    chatMemberRepository.save(new ChatMemberEntity(new ChatMemberId(saved.getId(), me)));
    chatMemberRepository.save(new ChatMemberEntity(new ChatMemberId(saved.getId(), otherUserId)));

    return toChatResponse(saved);
  }

  @PostMapping("/group")
  public ChatResponse createGroup(@Valid @RequestBody CreateGroupChatRequest req, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final long me = principal.getUserId();

    final Set<Long> members = new LinkedHashSet<>();
    members.add(me);
    members.addAll(req.memberIds);

    if (members.size() < 3) {
      throw new IllegalArgumentException("Group chats must have at least 3 members");
    }

    final ChatEntity chat = new ChatEntity();
    chat.setGroup(true);
    chat.setTitle(req.title.trim());
    chat.setLastMessage("");
    chat.setUpdatedAt(Instant.now());
    final ChatEntity saved = chatRepository.save(chat);

    for (final Long uid : members) {
      chatMemberRepository.save(new ChatMemberEntity(new ChatMemberId(saved.getId(), uid)));
    }

    return toChatResponse(saved);
  }

  @GetMapping("/{chatId}/messages")
  public List<ChatMessageResponse> messages(@PathVariable long chatId, Authentication authentication) {
    requireMember(chatId, authentication);
    return chatMessageRepository.findRecent(chatId).stream().map(this::toMessageResponse).toList();
  }

  @PostMapping("/{chatId}/messages")
  public ChatMessageResponse send(@PathVariable long chatId, @RequestBody SendMessageRequest req, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final long me = principal.getUserId();
    requireMember(chatId, authentication);

    final String type = req.type == null || req.type.trim().isEmpty() ? "text" : req.type.trim();
    final String text = req.text == null ? null : req.text.trim();
    final String mediaUrl = req.mediaUrl == null ? null : req.mediaUrl.trim();

    if (type.equals("text")) {
      if (text == null || text.isEmpty()) {
        throw new IllegalArgumentException("Text message cannot be empty");
      }
    } else {
      if (mediaUrl == null || mediaUrl.isEmpty()) {
        throw new IllegalArgumentException("Media message requires mediaUrl");
      }
    }

    final ChatMessageEntity m = new ChatMessageEntity();
    m.setChatId(chatId);
    m.setSenderId(me);
    m.setType(type);
    m.setText(text);
    m.setMediaUrl(mediaUrl);
    final ChatMessageEntity saved = chatMessageRepository.save(m);

    chatMessageSeenRepository.save(new ChatMessageSeenEntity(new ChatMessageSeenId(saved.getId(), me)));

    final ChatEntity chat = chatRepository.findById(chatId)
        .orElseThrow(() -> new IllegalArgumentException("Chat not found"));
    chat.setLastMessage(buildLastMessageLabel(type, text));
    chat.setUpdatedAt(Instant.now());
    chatRepository.save(chat);

    return toMessageResponse(saved);
  }

  @PostMapping("/{chatId}/messages/seen")
  public ResponseEntity<Void> markSeen(@PathVariable long chatId, @RequestBody MarkSeenRequest req, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final long me = principal.getUserId();
    requireMember(chatId, authentication);

    final List<Long> messageIds = req == null ? null : req.messageIds;
    if (messageIds == null) return ResponseEntity.noContent().build();

    for (final Long mid : messageIds) {
      if (mid == null) continue;
      final ChatMessageSeenId id = new ChatMessageSeenId(mid, me);
      if (!chatMessageSeenRepository.existsById(id)) {
        chatMessageSeenRepository.save(new ChatMessageSeenEntity(id));
      }
    }

    return ResponseEntity.noContent().build();
  }

  @PostMapping("/{chatId}/typing")
  public ResponseEntity<Void> setTyping(
      @PathVariable long chatId,
      @Valid @RequestBody TypingUpdateRequest req,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final long me = principal.getUserId();
    requireMember(chatId, authentication);

    final boolean typing = req != null && Boolean.TRUE.equals(req.isTyping);
    final ChatTypingId id = new ChatTypingId(chatId, me);
    final ChatTypingEntity row = chatTypingRepository.findById(id)
        .orElseGet(() -> new ChatTypingEntity(id, typing));

    row.setTyping(typing);
    row.setUpdatedAt(Instant.now());
    chatTypingRepository.save(row);
    return ResponseEntity.noContent().build();
  }

  @GetMapping("/{chatId}/typing")
  public List<Long> getTyping(@PathVariable long chatId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final long me = principal.getUserId();
    requireMember(chatId, authentication);

    final Instant cutoff = Instant.now().minusSeconds(6);
    final List<ChatTypingEntity> rows = chatTypingRepository.findActiveTyping(chatId, cutoff);
    final List<Long> ids = new ArrayList<>();
    for (final ChatTypingEntity t : rows) {
      final Long uid = t.getId() == null ? null : t.getId().getUserId();
      if (uid == null) continue;
      if (uid == me) continue;
      ids.add(uid);
    }
    return ids;
  }

  @PostMapping("/{chatId}/messages/{messageId}/reactions/{emoji}")
  public ResponseEntity<Void> toggleReaction(
      @PathVariable long chatId,
      @PathVariable long messageId,
      @PathVariable String emoji,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final long me = principal.getUserId();
    requireMember(chatId, authentication);

    final ChatMessageReactionId id = new ChatMessageReactionId(messageId, emoji, me);
    if (chatMessageReactionRepository.existsById(id)) {
      chatMessageReactionRepository.deleteById(id);
    } else {
      chatMessageReactionRepository.save(new ChatMessageReactionEntity(id));
    }

    return ResponseEntity.noContent().build();
  }

  private void requireMember(long chatId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final boolean isMember = chatMemberRepository.existsById(new ChatMemberId(chatId, principal.getUserId()));
    if (!isMember) {
      throw new IllegalArgumentException("Not a member of this chat");
    }
  }

  private ChatResponse toChatResponse(ChatEntity c) {
    final List<Long> members = chatMemberRepository.findMemberIds(c.getId());
    final List<UserEntity> users = userRepository.findAllById(members);
    final Map<Long, String> memberUsernames = new HashMap<>();
    for (final UserEntity u : users) {
      memberUsernames.put(u.getId(), u.getUsername());
    }

    return new ChatResponse(
        c.getId(),
        members,
        memberUsernames,
        c.getLastMessage(),
        c.getUpdatedAt(),
        c.isGroup(),
        c.getTitle());
  }

  private ChatMessageResponse toMessageResponse(ChatMessageEntity m) {
    final String senderUsername = userRepository.findById(m.getSenderId())
        .map(UserEntity::getUsername)
        .orElse("user");

    final List<Long> seenBy = chatMessageSeenRepository.findUserIdsWhoSaw(m.getId());

    final List<Object[]> rows = chatMessageReactionRepository.findEmojiAndUserId(m.getId());
    final Map<String, List<Long>> reactions = new HashMap<>();
    for (final Object[] row : rows) {
      final String emoji = (String) row[0];
      final Long uid = ((Number) row[1]).longValue();
      reactions.computeIfAbsent(emoji, k -> new ArrayList<>()).add(uid);
    }

    return new ChatMessageResponse(
        m.getId(),
        m.getSenderId(),
        senderUsername,
        m.getType(),
        m.getText(),
        m.getMediaUrl(),
        m.getCreatedAt(),
        reactions,
        seenBy);
  }

  private static String buildLastMessageLabel(String type, String text) {
    if (type == null) return "";
    if (type.equals("gif")) return "GIF";
    if (type.equals("image")) return "Photo";
    if (type.equals("video")) return "Video";
    if (type.equals("voice")) return "Voice message";
    if (type.equals("file")) return "File";
    return text == null ? "" : text;
  }
}
