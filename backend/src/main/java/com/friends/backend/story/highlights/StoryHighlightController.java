package com.friends.backend.story.highlights;

import com.friends.backend.block.UserBlockRepository;
import com.friends.backend.common.TrustSafetyUtils;
import com.friends.backend.follow.UserFollowRepository;
import com.friends.backend.mute.UserMuteRepository;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.story.StoryEntity;
import com.friends.backend.story.StoryLikeRepository;
import com.friends.backend.story.StoryRepository;
import com.friends.backend.story.StorySeenRepository;
import com.friends.backend.story.dto.StoryResponse;
import com.friends.backend.story.dto.StoryStickerResponse;
import com.friends.backend.story.highlights.dto.CreateHighlightRequest;
import com.friends.backend.story.highlights.dto.ReorderHighlightItemsRequest;
import com.friends.backend.story.highlights.dto.UpdateHighlightRequest;
import com.friends.backend.story.highlights.dto.HighlightItemRequest;
import com.friends.backend.story.highlights.dto.StoryHighlightResponse;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import jakarta.validation.Valid;
import java.util.*;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/story-highlights")
public class StoryHighlightController {
  private final StoryHighlightRepository highlightRepository;
  private final StoryHighlightItemRepository itemRepository;
  private final StoryRepository storyRepository;
  private final StorySeenRepository storySeenRepository;
  private final StoryLikeRepository storyLikeRepository;
  private final UserRepository userRepository;

  private final UserMuteRepository userMuteRepository;
  private final UserBlockRepository userBlockRepository;
  private final UserFollowRepository userFollowRepository;

  public StoryHighlightController(
      StoryHighlightRepository highlightRepository,
      StoryHighlightItemRepository itemRepository,
      StoryRepository storyRepository,
      StorySeenRepository storySeenRepository,
      StoryLikeRepository storyLikeRepository,
      UserRepository userRepository,
      UserMuteRepository userMuteRepository,
      UserBlockRepository userBlockRepository,
      UserFollowRepository userFollowRepository) {
    this.highlightRepository = highlightRepository;
    this.itemRepository = itemRepository;
    this.storyRepository = storyRepository;
    this.storySeenRepository = storySeenRepository;
    this.storyLikeRepository = storyLikeRepository;
    this.userRepository = userRepository;
    this.userMuteRepository = userMuteRepository;
    this.userBlockRepository = userBlockRepository;
    this.userFollowRepository = userFollowRepository;
  }

  private boolean canSeePrivateUser(Long meId, long ownerId) {
    if (meId != null && meId == ownerId) return true;
    final UserEntity owner = userRepository.findById(ownerId).orElse(null);
    if (owner == null) return false;
    final boolean isPrivate = Boolean.TRUE.equals(owner.getIsPrivateAccount());
    if (!isPrivate) return true;
    if (meId == null) return false;
    return userFollowRepository.existsAccepted(meId, ownerId);
  }

  @PatchMapping("/{highlightId}")
  public ResponseEntity<Void> update(
      @PathVariable long highlightId,
      @RequestBody UpdateHighlightRequest req,
      Authentication authentication) {
    final long me = requireAuth(authentication);
    final StoryHighlightEntity h = highlightRepository.findById(highlightId)
        .orElseThrow(() -> new IllegalArgumentException("Highlight not found"));
    if (h.getOwnerId() != me) throw new IllegalArgumentException("Forbidden");

    final String title = req == null || req.title == null ? "" : req.title.trim();
    if (title.isEmpty()) throw new IllegalArgumentException("Title is required");
    h.setTitle(title);
    highlightRepository.save(h);
    return ResponseEntity.noContent().build();
  }

  @PostMapping("/{highlightId}/reorder")
  public ResponseEntity<Void> reorder(
      @PathVariable long highlightId,
      @RequestBody ReorderHighlightItemsRequest req,
      Authentication authentication) {
    final long me = requireAuth(authentication);
    final StoryHighlightEntity h = highlightRepository.findById(highlightId)
        .orElseThrow(() -> new IllegalArgumentException("Highlight not found"));
    if (h.getOwnerId() != me) throw new IllegalArgumentException("Forbidden");

    final List<HighlightItemRequest> items = req == null ? null : req.items;
    if (items == null || items.isEmpty()) {
      throw new IllegalArgumentException("items required");
    }

    final Map<Long, StoryHighlightItemEntity> existing = new HashMap<>();
    for (final StoryHighlightItemEntity it : itemRepository.findByIdHighlightIdOrderByPositionAsc(highlightId)) {
      existing.put(it.getId().getStoryId(), it);
    }

    for (int i = 0; i < items.size(); i++) {
      final HighlightItemRequest r = items.get(i);
      if (r == null || r.storyId == null) continue;
      final long storyId = r.storyId;
      final int position = r.position != null ? r.position : i;

      final StoryHighlightItemEntity it = existing.get(storyId);
      if (it == null) {
        throw new IllegalArgumentException("Story not in highlight: " + storyId);
      }
      it.setPosition(position);
      itemRepository.save(it);
    }

    // touch highlight
    h.setTitle(h.getTitle());
    highlightRepository.save(h);

    return ResponseEntity.noContent().build();
  }

  @GetMapping("/user/{userId}")
  public List<StoryHighlightResponse> listByUser(@PathVariable long userId, Authentication authentication) {
    final Long meId = TrustSafetyUtils.getUserIdOrNull(authentication);
    final Set<Long> excluded = TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository);
    if (excluded.contains(userId)) {
      return List.of();
    }
    if (!canSeePrivateUser(meId, userId)) {
      return List.of();
    }

    final List<StoryHighlightEntity> highlights = highlightRepository.findByOwnerIdOrderByUpdatedAtDesc(userId);
    if (highlights.isEmpty()) return List.of();

    final List<Long> highlightIds = highlights.stream().map(StoryHighlightEntity::getId).toList();
    final List<StoryHighlightItemEntity> items = itemRepository.findByIdHighlightIdInOrderByIdHighlightIdAscPositionAsc(highlightIds);

    final Map<Long, List<StoryHighlightItemEntity>> itemsByHighlight = new HashMap<>();
    for (final StoryHighlightItemEntity it : items) {
      itemsByHighlight.computeIfAbsent(it.getId().getHighlightId(), k -> new ArrayList<>()).add(it);
    }

    // Fetch cover story for each highlight (last item by position)
    final Map<Long, Long> coverStoryIdByHighlight = new HashMap<>();
    final Set<Long> coverStoryIds = new HashSet<>();
    for (final StoryHighlightEntity h : highlights) {
      final List<StoryHighlightItemEntity> its = itemsByHighlight.getOrDefault(h.getId(), List.of());
      if (its.isEmpty()) continue;
      final StoryHighlightItemEntity last = its.get(its.size() - 1);
      final long storyId = last.getId().getStoryId();
      coverStoryIdByHighlight.put(h.getId(), storyId);
      coverStoryIds.add(storyId);
    }

    final Map<Long, StoryEntity> coverStories = new HashMap<>();
    if (!coverStoryIds.isEmpty()) {
      for (final StoryEntity s : storyRepository.findAllById(coverStoryIds)) {
        coverStories.put(s.getId(), s);
      }
    }

    final List<StoryHighlightResponse> out = new ArrayList<>();
    for (final StoryHighlightEntity h : highlights) {
      final List<StoryHighlightItemEntity> its = itemsByHighlight.getOrDefault(h.getId(), List.of());
      final int itemCount = its.size();
      final Long coverStoryId = coverStoryIdByHighlight.get(h.getId());
      final StoryEntity cover = coverStoryId == null ? null : coverStories.get(coverStoryId);
      final String coverMediaType = cover == null ? null : cover.getMediaType();
      final String coverMediaUrl = cover == null ? null : cover.getMediaUrl();
      final List<Long> storyIds = its.stream().map(i -> i.getId().getStoryId()).toList();

      out.add(new StoryHighlightResponse(
          h.getId(),
          h.getOwnerId(),
          h.getTitle(),
          h.getUpdatedAt() == null ? 0L : h.getUpdatedAt().toEpochMilli(),
          itemCount,
          coverStoryId,
          coverMediaType,
          coverMediaUrl,
          storyIds));
    }

    return out;
  }

  @GetMapping("/{highlightId}")
  public StoryHighlightResponse get(@PathVariable long highlightId, Authentication authentication) {
    final Long meId = TrustSafetyUtils.getUserIdOrNull(authentication);
    final StoryHighlightEntity h = highlightRepository.findById(highlightId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Highlight not found"));

    final Set<Long> excluded = TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository);
    if (excluded.contains(h.getOwnerId())) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Highlight not found");
    }
    if (!canSeePrivateUser(meId, h.getOwnerId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not allowed");
    }

    final List<StoryHighlightItemEntity> its = itemRepository.findByIdHighlightIdOrderByPositionAsc(highlightId);
    final List<Long> storyIds = its.stream().map(i -> i.getId().getStoryId()).toList();

    StoryEntity cover = null;
    Long coverStoryId = null;
    if (!its.isEmpty()) {
      coverStoryId = its.get(its.size() - 1).getId().getStoryId();
      cover = storyRepository.findById(coverStoryId).orElse(null);
    }

    return new StoryHighlightResponse(
        h.getId(),
        h.getOwnerId(),
        h.getTitle(),
        h.getUpdatedAt() == null ? 0L : h.getUpdatedAt().toEpochMilli(),
        its.size(),
        coverStoryId,
        cover == null ? null : cover.getMediaType(),
        cover == null ? null : cover.getMediaUrl(),
        storyIds);
  }

  @GetMapping("/{highlightId}/stories")
  public List<StoryResponse> stories(@PathVariable long highlightId, Authentication authentication) {
    final Long meId = TrustSafetyUtils.getUserIdOrNull(authentication);
    final StoryHighlightEntity h = highlightRepository.findById(highlightId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Highlight not found"));

    final Set<Long> excluded = TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository);
    if (excluded.contains(h.getOwnerId())) {
      return List.of();
    }
    if (!canSeePrivateUser(meId, h.getOwnerId())) {
      return List.of();
    }

    final List<StoryHighlightItemEntity> its = itemRepository.findByIdHighlightIdOrderByPositionAsc(highlightId);
    if (its.isEmpty()) return List.of();

    final List<Long> storyIds = its.stream().map(i -> i.getId().getStoryId()).toList();
    // Only include stories that belong to the highlight owner.
    final List<StoryEntity> stories = storyRepository.findAllById(storyIds)
        .stream()
        .filter(s -> Objects.equals(s.getAuthorId(), h.getOwnerId()))
        .collect(Collectors.toList());
    final Map<Long, StoryEntity> byId = new HashMap<>();
    for (final StoryEntity s : stories) {
      byId.put(s.getId(), s);
    }

    // Keep highlight order
    final List<StoryEntity> ordered = new ArrayList<>();
    for (final Long sid : storyIds) {
      final StoryEntity s = byId.get(sid);
      if (s != null) ordered.add(s);
    }

    return ordered.stream().map(s -> toStoryResponse(s)).toList();
  }

  @PostMapping
  public StoryHighlightResponse create(@Valid @RequestBody CreateHighlightRequest req, Authentication authentication) {
    final long me = requireAuth(authentication);
    final String title = req == null || req.title == null ? "" : req.title.trim();
    if (title.isEmpty()) throw new IllegalArgumentException("Title is required");

    final StoryHighlightEntity h = new StoryHighlightEntity();
    h.setOwnerId(me);
    h.setTitle(title);
    final StoryHighlightEntity saved = highlightRepository.save(h);

    return new StoryHighlightResponse(
        saved.getId(),
        saved.getOwnerId(),
        saved.getTitle(),
        saved.getUpdatedAt() == null ? 0L : saved.getUpdatedAt().toEpochMilli(),
        0,
        null,
        null,
        null,
        List.of());
  }

  @PostMapping("/{highlightId}/items")
  public ResponseEntity<Void> addItem(
      @PathVariable long highlightId,
      @RequestBody HighlightItemRequest req,
      Authentication authentication) {
    final long me = requireAuth(authentication);
    final StoryHighlightEntity h = highlightRepository.findById(highlightId)
        .orElseThrow(() -> new IllegalArgumentException("Highlight not found"));
    if (h.getOwnerId() != me) throw new IllegalArgumentException("Forbidden");

    final Long storyId = req == null ? null : req.storyId;
    if (storyId == null) throw new IllegalArgumentException("storyId required");

    // ensure story belongs to owner
    final StoryEntity story = storyRepository.findById(storyId)
        .orElseThrow(() -> new IllegalArgumentException("Story not found"));
    if (!Objects.equals(story.getAuthorId(), me)) {
      throw new IllegalArgumentException("You can only highlight your own stories");
    }

    final int position = req != null && req.position != null ? req.position : 0;
    final StoryHighlightItemId id = new StoryHighlightItemId(highlightId, storyId);
    if (!itemRepository.existsById(id)) {
      itemRepository.save(new StoryHighlightItemEntity(id, position));
    }

    // touch highlight
    h.setTitle(h.getTitle());
    highlightRepository.save(h);

    return ResponseEntity.noContent().build();
  }

  @DeleteMapping("/{highlightId}/items/{storyId}")
  public ResponseEntity<Void> removeItem(
      @PathVariable long highlightId,
      @PathVariable long storyId,
      Authentication authentication) {
    final long me = requireAuth(authentication);
    final StoryHighlightEntity h = highlightRepository.findById(highlightId)
        .orElseThrow(() -> new IllegalArgumentException("Highlight not found"));
    if (h.getOwnerId() != me) throw new IllegalArgumentException("Forbidden");

    itemRepository.deleteById(new StoryHighlightItemId(highlightId, storyId));

    // touch highlight
    h.setTitle(h.getTitle());
    highlightRepository.save(h);

    return ResponseEntity.noContent().build();
  }

  @DeleteMapping("/{highlightId}")
  public ResponseEntity<Void> delete(@PathVariable long highlightId, Authentication authentication) {
    final long me = requireAuth(authentication);
    final StoryHighlightEntity h = highlightRepository.findById(highlightId)
        .orElseThrow(() -> new IllegalArgumentException("Highlight not found"));
    if (h.getOwnerId() != me) throw new IllegalArgumentException("Forbidden");
    highlightRepository.deleteById(highlightId);
    return ResponseEntity.noContent().build();
  }

  private StoryResponse toStoryResponse(StoryEntity s) {
    final UserEntity author = userRepository.findById(s.getAuthorId()).orElse(null);
    final String authorUsername = author == null ? "user" : author.getUsername();
    final String authorThemeKey = author == null ? null : author.getThemeKey();
    final Integer authorThemeSeedColor = author == null ? null : author.getThemeSeedColor();

    final List<Long> seenBy = storySeenRepository.findUserIdsWhoSaw(s.getId());
    final List<Long> likedBy = storyLikeRepository.findUserIdsWhoLiked(s.getId());

    // Stickers are already included by /api/stories active endpoints; for highlights we keep it minimal.
    final List<StoryStickerResponse> stickers = List.of();

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
        stickers);
  }

  private long requireAuth(Authentication authentication) {
    if (authentication == null) {
      throw new IllegalArgumentException("Unauthorized");
    }
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return principal.getUserId();
  }
}
