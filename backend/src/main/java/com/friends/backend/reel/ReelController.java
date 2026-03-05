package com.friends.backend.reel;

import com.friends.backend.reel.dto.CreateReelRequest;
import com.friends.backend.reel.dto.ReelResponse;
import com.friends.backend.reel.dto.UpdateReelRequest;
import com.friends.backend.common.PagedResponse;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.List;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/reels")
public class ReelController {
  private final ReelRepository reelRepository;
  private final ReelLikeRepository reelLikeRepository;
  private final UserRepository userRepository;

  public ReelController(ReelRepository reelRepository, ReelLikeRepository reelLikeRepository, UserRepository userRepository) {
    this.reelRepository = reelRepository;
    this.reelLikeRepository = reelLikeRepository;
    this.userRepository = userRepository;
  }

  @GetMapping
  public List<ReelResponse> recent(
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit) {
    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));
    return reelRepository
        .findByArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(PageRequest.of(safePage, safeLimit))
        .stream()
        .map(this::toResponse)
        .toList();
  }

  @GetMapping("/paged")
  public PagedResponse<ReelResponse> recentPaged(
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit) {
    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));

    final List<ReelEntity> rows = reelRepository
        .findByArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(PageRequest.of(safePage, safeLimit + 1));
    final boolean hasMore = rows.size() > safeLimit;
    final List<ReelEntity> pageRows = hasMore ? rows.subList(0, safeLimit) : rows;
    final List<ReelResponse> items = pageRows.stream().map(this::toResponse).toList();

    return new PagedResponse<>(items, hasMore, hasMore ? safePage + 1 : null, null);
  }

  @GetMapping("/{reelId}")
  public ReelResponse byId(@PathVariable long reelId) {
    final ReelEntity reel = reelRepository.findById(reelId)
        .orElseThrow(() -> new IllegalArgumentException("Reel not found"));
    if (reel.getDeletedAt() != null) {
      throw new IllegalArgumentException("Reel is deleted");
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
