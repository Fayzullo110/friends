package com.friends.backend.reel;

import com.friends.backend.block.UserBlockRepository;
import com.friends.backend.common.TrustSafetyUtils;
import com.friends.backend.follow.UserFollowRepository;
import com.friends.backend.reel.dto.CreateReelRequest;
import com.friends.backend.reel.dto.ReelResponse;
import com.friends.backend.reel.dto.UpdateReelRequest;
import com.friends.backend.common.PagedResponse;
import com.friends.backend.mute.UserMuteRepository;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/reels")
public class ReelController {
  private final ReelRepository reelRepository;
  private final ReelLikeRepository reelLikeRepository;
  private final UserRepository userRepository;

  private final UserMuteRepository userMuteRepository;
  private final UserBlockRepository userBlockRepository;
  private final UserFollowRepository userFollowRepository;

  public ReelController(
      ReelRepository reelRepository,
      ReelLikeRepository reelLikeRepository,
      UserRepository userRepository,
      UserMuteRepository userMuteRepository,
      UserBlockRepository userBlockRepository,
      UserFollowRepository userFollowRepository) {
    this.reelRepository = reelRepository;
    this.reelLikeRepository = reelLikeRepository;
    this.userRepository = userRepository;
    this.userMuteRepository = userMuteRepository;
    this.userBlockRepository = userBlockRepository;
    this.userFollowRepository = userFollowRepository;
  }

  @GetMapping
  public List<ReelResponse> recent(
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit,
      Authentication authentication) {
    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));

    final Long meId = TrustSafetyUtils.getUserIdOrNull(authentication);
    final Set<Long> excluded = TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository);

    final List<ReelEntity> raw = reelRepository
        .findByArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(PageRequest.of(safePage, safeLimit))
        .stream()
        .filter(r -> r.getAuthorId() != null)
        .toList();

    final Set<Long> authorIds = raw.stream().map(ReelEntity::getAuthorId).filter(Objects::nonNull).collect(Collectors.toSet());
    final Map<Long, UserEntity> usersById = userRepository.findAllById(authorIds).stream()
        .collect(Collectors.toMap(UserEntity::getId, u -> u));
    final Set<Long> myFollowingIds = meId == null
        ? Set.of()
        : new HashSet<>(userFollowRepository.findFollowingIds(meId));

    final List<ReelEntity> reels = raw.stream()
        .filter(r -> r.getAuthorId() != null)
        .filter(r -> !excluded.contains(r.getAuthorId()))
        .filter(r -> TrustSafetyUtils.canSeePrivateUser(meId, r.getAuthorId(), usersById, myFollowingIds))
        .toList();

    return reels.stream().map(this::toResponse).toList();
  }

  @GetMapping("/paged")
  public PagedResponse<ReelResponse> recentPaged(
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit,
      Authentication authentication) {
    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));

    final List<ReelEntity> rows = reelRepository
        .findByArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(PageRequest.of(safePage, safeLimit + 1));

    final Long meId = TrustSafetyUtils.getUserIdOrNull(authentication);
    final Set<Long> excluded = TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository);

    final Set<Long> authorIds = rows.stream().map(ReelEntity::getAuthorId).filter(Objects::nonNull).collect(Collectors.toSet());
    final Map<Long, UserEntity> usersById = userRepository.findAllById(authorIds).stream()
        .collect(Collectors.toMap(UserEntity::getId, u -> u));
    final Set<Long> myFollowingIds = meId == null
        ? Set.of()
        : new HashSet<>(userFollowRepository.findFollowingIds(meId));

    final List<ReelEntity> filtered = rows.stream()
        .filter(r -> r.getAuthorId() != null)
        .filter(r -> !excluded.contains(r.getAuthorId()))
        .filter(r -> TrustSafetyUtils.canSeePrivateUser(meId, r.getAuthorId(), usersById, myFollowingIds))
        .toList();

    final boolean hasMore = filtered.size() > safeLimit;
    final List<ReelEntity> pageRows = hasMore ? filtered.subList(0, safeLimit) : filtered;
    final List<ReelResponse> items = pageRows.stream().map(this::toResponse).toList();

    return new PagedResponse<>(items, hasMore, hasMore ? safePage + 1 : null, null);
  }

  @GetMapping("/{reelId}")
  public ReelResponse byId(@PathVariable long reelId, Authentication authentication) {
    final ReelEntity reel = reelRepository.findById(reelId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Reel not found"));
    if (reel.getDeletedAt() != null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Reel not found");
    }

    final Long meId = TrustSafetyUtils.getUserIdOrNull(authentication);
    final Set<Long> excluded = TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository);
    final Long authorId = reel.getAuthorId();
    if (authorId == null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Reel not found");
    }
    if (excluded.contains(authorId)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not allowed");
    }

    final UserEntity author = userRepository.findById(authorId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Reel not found"));
    final boolean isPrivate = Boolean.TRUE.equals(author.getIsPrivateAccount());
    if (isPrivate) {
      if (meId == null || meId.longValue() != authorId.longValue()) {
        final boolean follows = meId != null && userFollowRepository.existsAccepted(meId, authorId);
        if (!follows) {
          throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not allowed");
        }
      }
    }

    return toResponse(reel);
  }

  @GetMapping("/archived")
  public List<ReelResponse> myArchived(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return reelRepository
        .findTop100ByAuthorIdAndArchivedAtIsNotNullAndDeletedAtIsNullOrderByArchivedAtDescCreatedAtDesc(
            principal.getUserId())
        .stream()
        .map(this::toResponse)
        .toList();
  }

  @PostMapping
  public ReelResponse create(@Valid @RequestBody CreateReelRequest req, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserEntity me = userRepository.findById(principal.getUserId())
        .orElseThrow(() -> new IllegalArgumentException("User not found"));

    final ReelEntity r = new ReelEntity();
    r.setAuthorId(me.getId());
    r.setCaption(req.caption.trim());
    r.setMediaUrl(req.mediaUrl == null || req.mediaUrl.trim().isEmpty() ? null : req.mediaUrl.trim());
    r.setMediaType(req.mediaType == null || req.mediaType.trim().isEmpty() ? "video" : req.mediaType.trim());

    return toResponse(reelRepository.save(r));
  }

  @PostMapping("/{reelId}/like")
  public ReelResponse toggleLike(@PathVariable long reelId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final ReelEntity reel = reelRepository.findById(reelId)
        .orElseThrow(() -> new IllegalArgumentException("Reel not found"));

    final ReelLikeId id = new ReelLikeId(reelId, principal.getUserId());
    if (reelLikeRepository.existsById(id)) {
      reelLikeRepository.deleteById(id);
      reel.setLikeCount(Math.max(0, reel.getLikeCount() - 1));
    } else {
      reelLikeRepository.save(new ReelLikeEntity(id));
      reel.setLikeCount(reel.getLikeCount() + 1);
    }

    return toResponse(reelRepository.save(reel));
  }

  @PostMapping("/{reelId}/share")
  public ResponseEntity<Void> share(@PathVariable long reelId) {
    final ReelEntity reel = reelRepository.findById(reelId)
        .orElseThrow(() -> new IllegalArgumentException("Reel not found"));
    reel.setShareCount(reel.getShareCount() + 1);
    reelRepository.save(reel);
    return ResponseEntity.noContent().build();
  }

  @PatchMapping("/{reelId}")
  public ReelResponse update(
      @PathVariable long reelId,
      @Valid @RequestBody UpdateReelRequest req,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final ReelEntity reel = reelRepository.findById(reelId)
        .orElseThrow(() -> new IllegalArgumentException("Reel not found"));
    if (!reel.getAuthorId().equals(principal.getUserId())) {
      throw new IllegalArgumentException("Not allowed");
    }
    if (reel.getDeletedAt() != null) {
      throw new IllegalArgumentException("Reel is deleted");
    }
    final String caption = req.caption == null ? "" : req.caption.trim();
    if (caption.isEmpty()) {
      throw new IllegalArgumentException("Caption cannot be empty");
    }
    reel.setCaption(caption);
    return toResponse(reelRepository.save(reel));
  }

  @PostMapping("/{reelId}/archive")
  public ResponseEntity<Void> archive(@PathVariable long reelId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final ReelEntity reel = reelRepository.findById(reelId)
        .orElseThrow(() -> new IllegalArgumentException("Reel not found"));
    if (!reel.getAuthorId().equals(principal.getUserId())) {
      throw new IllegalArgumentException("Not allowed");
    }
    if (reel.getDeletedAt() != null) {
      throw new IllegalArgumentException("Reel is deleted");
    }
    reel.setArchivedAt(Instant.now());
    reelRepository.save(reel);
    return ResponseEntity.noContent().build();
  }

  @PostMapping("/{reelId}/restore")
  public ResponseEntity<Void> restore(@PathVariable long reelId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final ReelEntity reel = reelRepository.findById(reelId)
        .orElseThrow(() -> new IllegalArgumentException("Reel not found"));
    if (!reel.getAuthorId().equals(principal.getUserId())) {
      throw new IllegalArgumentException("Not allowed");
    }
    if (reel.getDeletedAt() != null) {
      throw new IllegalArgumentException("Reel is deleted");
    }
    reel.setArchivedAt(null);
    reelRepository.save(reel);
    return ResponseEntity.noContent().build();
  }

  @DeleteMapping("/{reelId}")
  public ResponseEntity<Void> delete(@PathVariable long reelId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final ReelEntity reel = reelRepository.findById(reelId)
        .orElseThrow(() -> new IllegalArgumentException("Reel not found"));
    if (!reel.getAuthorId().equals(principal.getUserId())) {
      throw new IllegalArgumentException("Not allowed");
    }
    reel.setDeletedAt(Instant.now());
    reelRepository.save(reel);
    return ResponseEntity.noContent().build();
  }

  private ReelResponse toResponse(ReelEntity r) {
    final String authorUsername = userRepository.findById(r.getAuthorId())
        .map(UserEntity::getUsername)
        .orElse("user");
    final List<Long> likedBy = reelLikeRepository.findUserIdsWhoLiked(r.getId());
    return new ReelResponse(
        r.getId(),
        r.getAuthorId(),
        authorUsername,
        r.getCaption(),
        r.getMediaUrl(),
        r.getMediaType(),
        r.getLikeCount(),
        likedBy,
        r.getCommentCount(),
        r.getShareCount(),
        r.getCreatedAt(),
        r.getArchivedAt(),
        r.getDeletedAt());
  }
}
