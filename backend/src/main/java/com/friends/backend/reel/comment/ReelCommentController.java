package com.friends.backend.reel.comment;

import com.friends.backend.reel.ReelEntity;
import com.friends.backend.reel.ReelRepository;
import com.friends.backend.reel.comment.dto.CreateReelCommentRequest;
import com.friends.backend.reel.comment.dto.ReelCommentResponse;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/reels/{reelId}/comments")
public class ReelCommentController {
  private final ReelCommentRepository reelCommentRepository;
  private final ReelCommentLikeRepository reelCommentLikeRepository;
  private final ReelCommentDislikeRepository reelCommentDislikeRepository;
  private final ReelRepository reelRepository;
  private final UserRepository userRepository;

  public ReelCommentController(
      ReelCommentRepository reelCommentRepository,
      ReelCommentLikeRepository reelCommentLikeRepository,
      ReelCommentDislikeRepository reelCommentDislikeRepository,
      ReelRepository reelRepository,
      UserRepository userRepository) {
    this.reelCommentRepository = reelCommentRepository;
    this.reelCommentLikeRepository = reelCommentLikeRepository;
    this.reelCommentDislikeRepository = reelCommentDislikeRepository;
    this.reelRepository = reelRepository;
    this.userRepository = userRepository;
  }

  @GetMapping
  public List<ReelCommentResponse> list(@PathVariable long reelId) {
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

    final ReelEntity reel = reelRepository.findById(reelId)
        .orElseThrow(() -> new IllegalArgumentException("Reel not found"));

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
    final ReelCommentEntity comment = reelCommentRepository.findById(commentId)
        .orElseThrow(() -> new IllegalArgumentException("Comment not found"));

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
    final ReelCommentEntity comment = reelCommentRepository.findById(commentId)
        .orElseThrow(() -> new IllegalArgumentException("Comment not found"));

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
