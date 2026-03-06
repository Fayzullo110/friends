package com.friends.backend.story;

import com.friends.backend.block.UserBlockRepository;
import com.friends.backend.common.TrustSafetyUtils;
import com.friends.backend.follow.UserFollowRepository;
import com.friends.backend.mute.UserMuteRepository;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.story.dto.CreateStoryRequest;
import com.friends.backend.story.dto.StoryStickerEmojiSliderValueRequest;
import com.friends.backend.story.dto.StoryStickerPollVoteRequest;
import com.friends.backend.story.dto.StoryStickerQuestionAnswerRequest;
import com.friends.backend.story.dto.StoryStickerRequest;
import com.friends.backend.story.dto.StoryStickerResponse;
import com.friends.backend.story.dto.StoryResponse;
import com.friends.backend.story.stickers.StoryStickerEmojiSliderValueEntity;
import com.friends.backend.story.stickers.StoryStickerEmojiSliderValueId;
import com.friends.backend.story.stickers.StoryStickerEmojiSliderValueRepository;
import com.friends.backend.story.stickers.StoryStickerPollVoteEntity;
import com.friends.backend.story.stickers.StoryStickerPollVoteId;
import com.friends.backend.story.stickers.StoryStickerPollVoteRepository;
import com.friends.backend.story.stickers.StoryStickerQuestionAnswerEntity;
import com.friends.backend.story.stickers.StoryStickerQuestionAnswerId;
import com.friends.backend.story.stickers.StoryStickerQuestionAnswerRepository;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import jakarta.validation.Valid;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/stories")
public class StoryController {
  private final StoryRepository storyRepository;
  private final StorySeenRepository storySeenRepository;
  private final StoryLikeRepository storyLikeRepository;
  private final StoryStickerRepository storyStickerRepository;
  private final StoryStickerPollVoteRepository storyStickerPollVoteRepository;
  private final StoryStickerQuestionAnswerRepository storyStickerQuestionAnswerRepository;
  private final StoryStickerEmojiSliderValueRepository storyStickerEmojiSliderValueRepository;
  private final UserRepository userRepository;

  private final UserMuteRepository userMuteRepository;
  private final UserBlockRepository userBlockRepository;
  private final UserFollowRepository userFollowRepository;

  public StoryController(
      StoryRepository storyRepository,
      StorySeenRepository storySeenRepository,
      StoryLikeRepository storyLikeRepository,
      StoryStickerRepository storyStickerRepository,
      StoryStickerPollVoteRepository storyStickerPollVoteRepository,
      StoryStickerQuestionAnswerRepository storyStickerQuestionAnswerRepository,
      StoryStickerEmojiSliderValueRepository storyStickerEmojiSliderValueRepository,
      UserRepository userRepository,
      UserMuteRepository userMuteRepository,
      UserBlockRepository userBlockRepository,
      UserFollowRepository userFollowRepository) {
    this.storyRepository = storyRepository;
    this.storySeenRepository = storySeenRepository;
    this.storyLikeRepository = storyLikeRepository;
    this.storyStickerRepository = storyStickerRepository;
    this.storyStickerPollVoteRepository = storyStickerPollVoteRepository;
    this.storyStickerQuestionAnswerRepository = storyStickerQuestionAnswerRepository;
    this.storyStickerEmojiSliderValueRepository = storyStickerEmojiSliderValueRepository;
    this.userRepository = userRepository;
    this.userMuteRepository = userMuteRepository;
    this.userBlockRepository = userBlockRepository;
    this.userFollowRepository = userFollowRepository;
  }

  @GetMapping
  public List<StoryResponse> active(Authentication authentication) {
    final Instant now = Instant.now();
    final Long meId = TrustSafetyUtils.getUserIdOrNull(authentication);
    final Set<Long> excluded = TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository);

    final List<StoryEntity> raw = storyRepository
        .findTop200ByExpiresAtAfterOrderByExpiresAtAscCreatedAtDesc(now);

    final Set<Long> authorIds = raw.stream().map(StoryEntity::getAuthorId).filter(Objects::nonNull).collect(Collectors.toSet());
    final Map<Long, UserEntity> usersById = userRepository.findAllById(authorIds).stream()
        .collect(Collectors.toMap(UserEntity::getId, u -> u));
    final Set<Long> myFollowingIds = meId == null
        ? Set.of()
        : new HashSet<>(userFollowRepository.findFollowingIds(meId));

    final List<StoryEntity> stories = raw.stream()
        .filter(s -> s.getAuthorId() != null)
        .filter(s -> !excluded.contains(s.getAuthorId()))
        .filter(s -> TrustSafetyUtils.canSeePrivateUser(meId, s.getAuthorId(), usersById, myFollowingIds))
        .toList();
    final StickersPrefetch prefetch = prefetchStickers(stories, meId);
    return stories.stream().map(s -> toResponse(s, prefetch, meId)).toList();
  }

  @GetMapping("/user/{authorId}")
  public List<StoryResponse> activeByUser(@PathVariable long authorId, Authentication authentication) {
    final Instant now = Instant.now();
    final Long meId = TrustSafetyUtils.getUserIdOrNull(authentication);

    if (meId == null || meId != authorId) {
      final UserEntity author = userRepository.findById(authorId).orElse(null);
      if (author == null) {
        throw new IllegalArgumentException("User not found");
      }
      if (Boolean.TRUE.equals(author.getIsPrivateAccount())) {
        if (meId == null) {
          return List.of();
        }
        final boolean follows = userFollowRepository.existsAccepted(meId, authorId);
        if (!follows) {
          return List.of();
        }
      }
    }

    final Set<Long> excluded = TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository);
    if (excluded.contains(authorId)) {
      return List.of();
    }

    final List<StoryEntity> stories = storyRepository
        .findTop200ByAuthorIdAndExpiresAtAfterOrderByExpiresAtAscCreatedAtDesc(authorId, now);
    final StickersPrefetch prefetch = prefetchStickers(stories, meId);
    return stories.stream().map(s -> toResponse(s, prefetch, meId)).toList();
  }

  @GetMapping("/{storyId}")
  public StoryResponse byId(@PathVariable long storyId, Authentication authentication) {
    final Long meId = TrustSafetyUtils.getUserIdOrNull(authentication);
    final Set<Long> excluded = TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository);

    final StoryEntity story = storyRepository.findById(storyId)
        .orElseThrow(() -> new IllegalArgumentException("Story not found"));
    final Long authorId = story.getAuthorId();
    if (authorId == null) {
      throw new IllegalArgumentException("Story not found");
    }
    if (excluded.contains(authorId)) {
      throw new IllegalArgumentException("Story not found");
    }

    final UserEntity author = userRepository.findById(authorId).orElse(null);
    if (author == null) {
      throw new IllegalArgumentException("Story not found");
    }
    if (Boolean.TRUE.equals(author.getIsPrivateAccount())) {
      if (meId == null) {
        throw new IllegalArgumentException("Story not found");
      }
      if (meId != authorId && !userFollowRepository.existsAccepted(meId, authorId)) {
        throw new IllegalArgumentException("Story not found");
      }
    }

    final StickersPrefetch prefetch = prefetchStickers(List.of(story), meId);
    return toResponse(story, prefetch, meId);
  }

  @PostMapping
  public StoryResponse create(@Valid @RequestBody CreateStoryRequest req, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserEntity me = userRepository.findById(principal.getUserId())
        .orElseThrow(() -> new IllegalArgumentException("User not found"));

    final StoryEntity s = new StoryEntity();
    s.setAuthorId(me.getId());
    s.setMediaUrl(req.mediaUrl == null || req.mediaUrl.trim().isEmpty() ? null : req.mediaUrl.trim());
    s.setMediaType(req.mediaType == null || req.mediaType.trim().isEmpty() ? "text" : req.mediaType.trim());
    s.setText(req.text == null || req.text.trim().isEmpty() ? null : req.text.trim());
    s.setMusicTitle(req.musicTitle);
    s.setMusicArtist(req.musicArtist);
    s.setMusicUrl(req.musicUrl);
    s.setExpiresAt(Instant.now().plus(24, ChronoUnit.HOURS));

    final StoryEntity saved = storyRepository.save(s);

    if (req != null && req.stickers != null && !req.stickers.isEmpty()) {
      for (final StoryStickerRequest r : req.stickers) {
        if (r == null) continue;
        final String type = r.type == null ? "" : r.type.trim();
        if (type.isEmpty()) continue;
        final Double x = r.posX == null ? 0.5 : r.posX;
        final Double y = r.posY == null ? 0.5 : r.posY;

        final StoryStickerEntity st = new StoryStickerEntity();
        st.setStoryId(saved.getId());
        st.setType(type);
        st.setPosX(x);
        st.setPosY(y);
        st.setDataJson(r.dataJson);
        storyStickerRepository.save(st);
      }
    }

    final Long meId = principal.getUserId();
    final StickersPrefetch prefetch = prefetchStickers(List.of(saved), meId);
    return toResponse(saved, prefetch, meId);
  }

  @PostMapping("/{storyId}/stickers/{stickerId}/poll-vote")
  public ResponseEntity<Void> votePoll(
      @PathVariable long storyId,
      @PathVariable long stickerId,
      @RequestBody StoryStickerPollVoteRequest req,
      Authentication authentication) {
    final long me = requireAuth(authentication);
    final StoryStickerEntity sticker = requireSticker(storyId, stickerId);
    final Integer option = req == null ? null : req.optionIndex;
    if (option == null || option < 0) {
      throw new IllegalArgumentException("Invalid optionIndex");
    }

    final StoryStickerPollVoteId id = new StoryStickerPollVoteId(sticker.getId(), me);
    final StoryStickerPollVoteEntity row = storyStickerPollVoteRepository.findById(id)
        .orElseGet(() -> new StoryStickerPollVoteEntity(id, option));
    row.setOptionIndex(option);
    storyStickerPollVoteRepository.save(row);
    return ResponseEntity.noContent().build();
  }

  @PostMapping("/{storyId}/stickers/{stickerId}/question-answer")
  public ResponseEntity<Void> answerQuestion(
      @PathVariable long storyId,
      @PathVariable long stickerId,
      @RequestBody StoryStickerQuestionAnswerRequest req,
      Authentication authentication) {
    final long me = requireAuth(authentication);
    final StoryStickerEntity sticker = requireSticker(storyId, stickerId);
    final String answer = req == null || req.answerText == null ? "" : req.answerText.trim();
    if (answer.isEmpty()) {
      throw new IllegalArgumentException("Answer cannot be empty");
    }

    final StoryStickerQuestionAnswerId id = new StoryStickerQuestionAnswerId(sticker.getId(), me);
    final StoryStickerQuestionAnswerEntity row = storyStickerQuestionAnswerRepository.findById(id)
        .orElseGet(() -> new StoryStickerQuestionAnswerEntity(id, answer));
    row.setAnswerText(answer);
    storyStickerQuestionAnswerRepository.save(row);
    return ResponseEntity.noContent().build();
  }

  @PostMapping("/{storyId}/stickers/{stickerId}/emoji-slider")
  public ResponseEntity<Void> setEmojiSlider(
      @PathVariable long storyId,
      @PathVariable long stickerId,
      @RequestBody StoryStickerEmojiSliderValueRequest req,
      Authentication authentication) {
    final long me = requireAuth(authentication);
    final StoryStickerEntity sticker = requireSticker(storyId, stickerId);
    final Integer value = req == null ? null : req.value;
    if (value == null || value < 0 || value > 100) {
      throw new IllegalArgumentException("Invalid value");
    }

    final StoryStickerEmojiSliderValueId id = new StoryStickerEmojiSliderValueId(sticker.getId(), me);
    final StoryStickerEmojiSliderValueEntity row = storyStickerEmojiSliderValueRepository.findById(id)
        .orElseGet(() -> new StoryStickerEmojiSliderValueEntity(id, value));
    row.setValueInt(value);
    storyStickerEmojiSliderValueRepository.save(row);
    return ResponseEntity.noContent().build();
  }

  private long requireAuth(Authentication authentication) {
    if (authentication == null) {
      throw new IllegalArgumentException("Unauthorized");
    }
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return principal.getUserId();
  }

  private StoryStickerEntity requireSticker(long storyId, long stickerId) {
    final StoryStickerEntity sticker = storyStickerRepository.findById(stickerId).orElse(null);
    if (sticker == null || sticker.getStoryId() == null || sticker.getStoryId() != storyId) {
      throw new IllegalArgumentException("Sticker not found");
    }
    return sticker;
  }

  @PostMapping("/{storyId}/seen")
  public ResponseEntity<Void> markSeen(@PathVariable long storyId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final StorySeenId id = new StorySeenId(storyId, principal.getUserId());
    if (!storySeenRepository.existsById(id)) {
      storySeenRepository.save(new StorySeenEntity(id));
    }
    return ResponseEntity.noContent().build();
  }

  @PostMapping("/{storyId}/like")
  public ResponseEntity<Void> toggleLike(@PathVariable long storyId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final StoryLikeId id = new StoryLikeId(storyId, principal.getUserId());
    if (storyLikeRepository.existsById(id)) {
      storyLikeRepository.deleteById(id);
    } else {
      storyLikeRepository.save(new StoryLikeEntity(id));
    }
    return ResponseEntity.noContent().build();
  }

  private record StickersPrefetch(
      Map<Long, List<StoryStickerEntity>> stickersByStoryId,
      Map<Long, Map<Long, Integer>> pollChoiceByStickerByUser,
      Map<Long, Map<Integer, Long>> pollCountsBySticker,
      Map<Long, Long> questionCountBySticker,
      Map<Long, Map<Long, String>> questionAnswerByStickerByUser,
      Map<Long, Double> emojiAvgBySticker,
      Map<Long, Long> emojiCountBySticker,
      Map<Long, Map<Long, Integer>> emojiValueByStickerByUser) {}

  private StickersPrefetch prefetchStickers(List<StoryEntity> stories, Long meId) {
    final List<Long> storyIds = stories.stream().map(StoryEntity::getId).filter(Objects::nonNull).toList();
    if (storyIds.isEmpty()) {
      return new StickersPrefetch(
          new HashMap<>(), new HashMap<>(), new HashMap<>(), new HashMap<>(), new HashMap<>(),
          new HashMap<>(), new HashMap<>(), new HashMap<>());
    }

    final List<StoryStickerEntity> stickers = storyStickerRepository.findByStoryIdInOrderByStoryIdAscIdAsc(storyIds);
    final Map<Long, List<StoryStickerEntity>> stickersByStoryId = new HashMap<>();
    final List<Long> stickerIds = new ArrayList<>();
    for (final StoryStickerEntity st : stickers) {
      stickersByStoryId.computeIfAbsent(st.getStoryId(), k -> new ArrayList<>()).add(st);
      if (st.getId() != null) stickerIds.add(st.getId());
    }

    final Map<Long, Map<Integer, Long>> pollCountsBySticker = new HashMap<>();
    final Map<Long, Map<Long, Integer>> pollChoiceByStickerByUser = new HashMap<>();
    final Map<Long, Long> questionCountBySticker = new HashMap<>();
    final Map<Long, Map<Long, String>> questionAnswerByStickerByUser = new HashMap<>();
    final Map<Long, Double> emojiAvgBySticker = new HashMap<>();
    final Map<Long, Long> emojiCountBySticker = new HashMap<>();
    final Map<Long, Map<Long, Integer>> emojiValueByStickerByUser = new HashMap<>();

    if (!stickerIds.isEmpty()) {
      // Poll votes
      for (final Object[] row : storyStickerPollVoteRepository.findVotesForStickers(stickerIds)) {
        final long stid = ((Number) row[0]).longValue();
        final long uid = ((Number) row[1]).longValue();
        final int option = ((Number) row[2]).intValue();
        pollCountsBySticker.computeIfAbsent(stid, k -> new HashMap<>())
            .merge(option, 1L, (a, b) -> a + b);
        pollChoiceByStickerByUser.computeIfAbsent(stid, k -> new HashMap<>())
            .put(uid, option);
      }

      // Question answers
      for (final Object[] row : storyStickerQuestionAnswerRepository.findAnswersForStickers(stickerIds)) {
        final long stid = ((Number) row[0]).longValue();
        final long uid = ((Number) row[1]).longValue();
        final String answer = row[2] == null ? "" : row[2].toString();
        questionAnswerByStickerByUser.computeIfAbsent(stid, k -> new HashMap<>())
            .put(uid, answer);
        questionCountBySticker.merge(stid, 1L, (a, b) -> a + b);
      }

      // Emoji slider
      for (final Object[] row : storyStickerEmojiSliderValueRepository.findValuesForStickers(stickerIds)) {
        final long stid = ((Number) row[0]).longValue();
        final long uid = ((Number) row[1]).longValue();
        final int value = ((Number) row[2]).intValue();
        emojiValueByStickerByUser.computeIfAbsent(stid, k -> new HashMap<>())
            .put(uid, value);
      }
      for (final Object[] row : storyStickerEmojiSliderValueRepository.avgForStickers(stickerIds)) {
        final long stid = ((Number) row[0]).longValue();
        final double avg = row[1] == null ? 0.0 : ((Number) row[1]).doubleValue();
        final long cnt = row[2] == null ? 0L : ((Number) row[2]).longValue();
        emojiAvgBySticker.put(stid, avg);
        emojiCountBySticker.put(stid, cnt);
      }
    }

    return new StickersPrefetch(
        stickersByStoryId,
        pollChoiceByStickerByUser,
        pollCountsBySticker,
        questionCountBySticker,
        questionAnswerByStickerByUser,
        emojiAvgBySticker,
        emojiCountBySticker,
        emojiValueByStickerByUser);
  }

  private StoryResponse toResponse(StoryEntity s, StickersPrefetch prefetch, Long meId) {
    final UserEntity author = userRepository.findById(s.getAuthorId()).orElse(null);
    final String authorUsername = author == null ? "user" : author.getUsername();
    final String authorThemeKey = author == null ? null : author.getThemeKey();
    final Integer authorThemeSeedColor = author == null ? null : author.getThemeSeedColor();

    final List<Long> seenBy = storySeenRepository.findUserIdsWhoSaw(s.getId());

    final List<Long> likedBy = storyLikeRepository.findUserIdsWhoLiked(s.getId());

    final List<StoryStickerEntity> stickers = prefetch == null
        ? storyStickerRepository.findByStoryIdOrderByIdAsc(s.getId())
        : (prefetch.stickersByStoryId().getOrDefault(s.getId(), List.of()));
    final List<StoryStickerResponse> stickerResponses = new ArrayList<>();
    for (final StoryStickerEntity st : stickers) {
      final long sid = st.getId();

      final Map<Integer, Long> pollCounts = prefetch == null
          ? null
          : prefetch.pollCountsBySticker().get(sid);
      final Integer myPollChoice = (meId == null || prefetch == null)
          ? null
          : prefetch.pollChoiceByStickerByUser().getOrDefault(sid, Map.of()).get(meId);

      final Long questionCount = prefetch == null
          ? null
          : prefetch.questionCountBySticker().getOrDefault(sid, 0L);
      final String myAnswer = (meId == null || prefetch == null)
          ? null
          : prefetch.questionAnswerByStickerByUser().getOrDefault(sid, Map.of()).get(meId);

      final Double emojiAvg = prefetch == null
          ? null
          : prefetch.emojiAvgBySticker().getOrDefault(sid, null);
      final Long emojiCount = prefetch == null
          ? null
          : prefetch.emojiCountBySticker().getOrDefault(sid, 0L);
      final Integer myEmoji = (meId == null || prefetch == null)
          ? null
          : prefetch.emojiValueByStickerByUser().getOrDefault(sid, Map.of()).get(meId);

      stickerResponses.add(new StoryStickerResponse(
          st.getId(),
          st.getType(),
          st.getPosX(),
          st.getPosY(),
          st.getDataJson(),
          pollCounts,
          myPollChoice,
          questionCount,
          myAnswer,
          emojiAvg,
          emojiCount,
          myEmoji));
    }

    return new StoryResponse(
        s.getId(),
        s.getAuthorId(),
        authorUsername,
        authorThemeKey,
        authorThemeSeedColor,
        s.getMediaUrl(),
        s.getMediaType(),
        s.getText(),
        s.getCreatedAt(),
        s.getExpiresAt(),
        seenBy,
        likedBy,
        s.getMusicTitle(),
        s.getMusicArtist(),
        s.getMusicUrl(),
        stickerResponses);
  }
}
