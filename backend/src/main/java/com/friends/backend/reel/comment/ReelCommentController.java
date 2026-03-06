package com.friends.backend.reel.comment;

import com.friends.backend.block.UserBlockId;
import com.friends.backend.block.UserBlockRepository;
import com.friends.backend.follow.UserFollowRepository;
import com.friends.backend.reel.ReelEntity;
import com.friends.backend.reel.ReelRepository;
import com.friends.backend.reel.comment.dto.CreateReelCommentRequest;
import com.friends.backend.reel.comment.dto.ReelCommentResponse;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/reels/{reelId}/comments")
public class ReelCommentController {
  private final ReelCommentRepository reelCommentRepository;
  private final ReelCommentLikeRepository reelCommentLikeRepository;
  private final ReelCommentDislikeRepository reelCommentDislikeRepository;
  private final ReelRepository reelRepository;
  private final UserRepository userRepository;

  private final UserBlockRepository userBlockRepository;
  private final UserFollowRepository userFollowRepository;

  public ReelCommentController(
      ReelCommentRepository reelCommentRepository,
      ReelCommentLikeRepository reelCommentLikeRepository,
      ReelCommentDislikeRepository reelCommentDislikeRepository,
      ReelRepository reelRepository,
      UserRepository userRepository,
      UserBlockRepository userBlockRepository,
      UserFollowRepository userFollowRepository) {
    this.reelCommentRepository = reelCommentRepository;
    this.reelCommentLikeRepository = reelCommentLikeRepository;
    this.reelCommentDislikeRepository = reelCommentDislikeRepository;
    this.reelRepository = reelRepository;
    this.userRepository = userRepository;
    this.userBlockRepository = userBlockRepository;
    this.userFollowRepository = userFollowRepository;
  }

  private Long getUserIdOrNull(Authentication authentication) {
    if (authentication == null) return null;
    final Object p = authentication.getPrincipal();
    if (!(p instanceof UserPrincipal principal)) return null;
    return principal.getUserId();
  }

  private UserEntity requireUser(long userId, String notFoundMsg) {
    return userRepository.findById(userId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, notFoundMsg));
  }

  private ReelEntity requireReel(long reelId) {
    final ReelEntity reel = reelRepository.findById(reelId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Reel not found"));
    if (reel.getDeletedAt() != null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Reel not found");
    }
    return reel;
  }

  private void ensureCanViewReel(Long meId, ReelEntity reel) {
    final Long authorId = reel.getAuthorId();
    if (authorId == null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Reel not found");
    }

    final UserEntity author = requireUser(authorId, "Reel author not found");

    if (meId != null) {
      if (userBlockRepository.existsById(new UserBlockId(meId, authorId))
          || userBlockRepository.existsById(new UserBlockId(authorId, meId))) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not allowed");
      }
    }

    final boolean isPrivate = Boolean.TRUE.equals(author.getIsPrivateAccount());
    if (isPrivate) {
      if (meId == null || meId.longValue() != authorId.longValue()) {
        final boolean follows = meId != null && userFollowRepository.existsAccepted(meId, authorId);
        if (!follows) {
          throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not allowed");
        }
      }
    }
  }

  @GetMapping
  public List<ReelCommentResponse> list(@PathVariable long reelId, Authentication authentication) {
    final Long meId = getUserIdOrNull(authentication);
    final ReelEntity reel = requireReel(reelId);
    ensureCanViewReel(meId, reel);
    return reelCommentRepository.findByReelIdOrderByCreatedAtAsc(reelId)
        .stream()
        .map(this::toResponse)
        .toList();
  }

  @PostMapping
  public ReelCommentResponse create(
      @PathVariable long reelId,
      @Valid @RequestBody CreateReelCommentRequest req,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserEntity me = userRepository.findById(principal.getUserId())
        .orElseThrow(() -> new IllegalArgumentException("User not found"));

    final ReelEntity reel = requireReel(reelId);
    final Long authorId = reel.getAuthorId();
    if (authorId == null) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Reel not found");
    }
    final UserEntity author = requireUser(authorId, "Reel not found");

    if (userBlockRepository.existsById(new UserBlockId(me.getId(), author.getId()))
        || userBlockRepository.existsById(new UserBlockId(author.getId(), me.getId()))) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not allowed");
    }

    final boolean isPrivate = Boolean.TRUE.equals(author.getIsPrivateAccount());
    if (isPrivate && !author.getId().equals(me.getId())) {
      final boolean follows = userFollowRepository.existsAccepted(me.getId(), author.getId());
      if (!follows) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not allowed");
      }
    }

    final String policy = author.getCommentPolicy() == null
        ? "everyone"
        : author.getCommentPolicy().trim().toLowerCase();
    if (author.getId().equals(me.getId())) {
      // Always allow commenting on my own reel.
    } else if (policy.equals("no_one")) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not allowed");
    } else if (policy.equals("followers")) {
      final boolean follows = userFollowRepository.existsAccepted(me.getId(), author.getId());
      if (!follows) {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not allowed");
      }
    }

    final ReelCommentEntity c = new ReelCommentEntity();
    c.setReelId(reelId);
    c.setAuthorId(me.getId());
    c.setText(req.text.trim());
    c.setType(req.type == null || req.type.trim().isEmpty() ? "text" : req.type.trim());
    c.setMediaUrl(req.mediaUrl == null || req.mediaUrl.trim().isEmpty() ? null : req.mediaUrl.trim());

    final ReelCommentEntity saved = reelCommentRepository.save(c);

    reel.setCommentCount(reel.getCommentCount() + 1);
    reelRepository.save(reel);

    return toResponse(saved);
  }

  @PostMapping("/{commentId}/like")
  public ReelCommentResponse toggleLike(
      @PathVariable long reelId,
      @PathVariable long commentId,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final ReelEntity reel = requireReel(reelId);
    ensureCanViewReel(principal.getUserId(), reel);
    final ReelCommentEntity comment = reelCommentRepository.findById(commentId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Comment not found"));

    if (!comment.getReelId().equals(reelId)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Comment not found");
    }

    final ReelCommentReactionId id = new ReelCommentReactionId(commentId, principal.getUserId());
    if (reelCommentLikeRepository.existsById(id)) {
      reelCommentLikeRepository.deleteById(id);
      comment.setLikeCount(Math.max(0, comment.getLikeCount() - 1));
    } else {
      if (reelCommentDislikeRepository.existsById(id)) {
        reelCommentDislikeRepository.deleteById(id);
        comment.setDislikeCount(Math.max(0, comment.getDislikeCount() - 1));
      }
      reelCommentLikeRepository.save(new ReelCommentLikeEntity(id));
      comment.setLikeCount(comment.getLikeCount() + 1);
    }

    return toResponse(reelCommentRepository.save(comment));
  }

  @PostMapping("/{commentId}/dislike")
  public ReelCommentResponse toggleDislike(
      @PathVariable long reelId,
      @PathVariable long commentId,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final ReelEntity reel = requireReel(reelId);
    ensureCanViewReel(principal.getUserId(), reel);
    final ReelCommentEntity comment = reelCommentRepository.findById(commentId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Comment not found"));

    if (!comment.getReelId().equals(reelId)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Comment not found");
    }

    final ReelCommentReactionId id = new ReelCommentReactionId(commentId, principal.getUserId());
    if (reelCommentDislikeRepository.existsById(id)) {
      reelCommentDislikeRepository.deleteById(id);
      comment.setDislikeCount(Math.max(0, comment.getDislikeCount() - 1));
    } else {
      if (reelCommentLikeRepository.existsById(id)) {
        reelCommentLikeRepository.deleteById(id);
        comment.setLikeCount(Math.max(0, comment.getLikeCount() - 1));
      }
      reelCommentDislikeRepository.save(new ReelCommentDislikeEntity(id));
      comment.setDislikeCount(comment.getDislikeCount() + 1);
    }

    return toResponse(reelCommentRepository.save(comment));
  }

  private ReelCommentResponse toResponse(ReelCommentEntity c) {
    final String authorUsername = userRepository.findById(c.getAuthorId())
        .map(UserEntity::getUsername)
        .orElse("user");

    final List<Long> likedBy = reelCommentLikeRepository.findUserIdsWhoLiked(c.getId());
    final List<Long> dislikedBy = reelCommentDislikeRepository.findUserIdsWhoDisliked(c.getId());

    return new ReelCommentResponse(
        c.getId(),
        c.getReelId(),
        c.getAuthorId(),
        authorUsername,
        c.getText(),
        c.getType(),
        c.getMediaUrl(),
        c.getCreatedAt(),
        c.getLikeCount(),
        likedBy,
        c.getDislikeCount(),
        dislikedBy);
  }
}
