package com.friends.backend.comment;

import com.friends.backend.block.UserBlockId;
import com.friends.backend.block.UserBlockRepository;
import com.friends.backend.follow.UserFollowId;
import com.friends.backend.follow.UserFollowRepository;
import com.friends.backend.comment.dto.CommentResponse;
import com.friends.backend.comment.dto.CreateCommentRequest;
import com.friends.backend.post.PostEntity;
import com.friends.backend.post.PostRepository;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/posts/{postId}/comments")
public class CommentController {
  private final CommentRepository commentRepository;
  private final CommentLikeRepository commentLikeRepository;
  private final CommentDislikeRepository commentDislikeRepository;
  private final PostRepository postRepository;
  private final UserRepository userRepository;
  private final UserFollowRepository userFollowRepository;
  private final UserBlockRepository userBlockRepository;

  public CommentController(
      CommentRepository commentRepository,
      CommentLikeRepository commentLikeRepository,
      CommentDislikeRepository commentDislikeRepository,
      PostRepository postRepository,
      UserRepository userRepository,
      UserFollowRepository userFollowRepository,
      UserBlockRepository userBlockRepository) {
    this.commentRepository = commentRepository;
    this.commentLikeRepository = commentLikeRepository;
    this.commentDislikeRepository = commentDislikeRepository;
    this.postRepository = postRepository;
    this.userRepository = userRepository;
    this.userFollowRepository = userFollowRepository;
    this.userBlockRepository = userBlockRepository;
  }

  @GetMapping
  public List<CommentResponse> list(@PathVariable long postId) {
    return commentRepository.findByPostIdOrderByCreatedAtAsc(postId)
        .stream()
        .map(this::toResponse)
        .toList();
  }

  @PostMapping
  public CommentResponse create(
      @PathVariable long postId,
      @Valid @RequestBody CreateCommentRequest req,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserEntity me = userRepository.findById(principal.getUserId())
        .orElseThrow(() -> new IllegalArgumentException("User not found"));

    final PostEntity post = postRepository.findById(postId)
        .orElseThrow(() -> new IllegalArgumentException("Post not found"));
    if (post.getDeletedAt() != null) {
      throw new IllegalArgumentException("Post is deleted");
    }

    final UserEntity postAuthor = userRepository.findById(post.getAuthorId())
        .orElseThrow(() -> new IllegalArgumentException("Post author not found"));

    if (userBlockRepository.existsById(new UserBlockId(me.getId(), postAuthor.getId()))
        || userBlockRepository.existsById(new UserBlockId(postAuthor.getId(), me.getId()))) {
      throw new IllegalArgumentException("You can't comment because there is a block between you.");
    }

    final String policy = postAuthor.getCommentPolicy() == null
        ? "everyone"
        : postAuthor.getCommentPolicy().trim().toLowerCase();
    if (postAuthor.getId().equals(me.getId())) {
      // Always allow commenting on my own post.
    } else if (policy.equals("no_one")) {
      throw new IllegalArgumentException("Comments are disabled for this user.");
    } else if (policy.equals("followers")) {
      final boolean follows = userFollowRepository.existsById(
          new UserFollowId(me.getId(), postAuthor.getId()));
      if (!follows) {
        throw new IllegalArgumentException("Only followers can comment.");
      }
    }

    final String type = req.type == null || req.type.trim().isEmpty() ? "text" : req.type.trim();
    final String text = req.text == null ? null : req.text.trim();
    final String mediaUrl = req.mediaUrl == null ? null : req.mediaUrl.trim();
    if (type.equals("text")) {
      if (text == null || text.isEmpty()) {
        throw new IllegalArgumentException("Comment text cannot be empty");
      }
    } else {
      if (mediaUrl == null || mediaUrl.isEmpty()) {
        throw new IllegalArgumentException("GIF comment requires mediaUrl");
      }
    }

    final CommentEntity c = new CommentEntity();
    c.setPostId(postId);
    c.setAuthorId(me.getId());
    c.setText(text == null || text.isEmpty() ? "" : text);
    c.setType(type);
    c.setMediaUrl(mediaUrl == null || mediaUrl.isEmpty() ? null : mediaUrl);
    c.setParentCommentId(req.parentCommentId);

    final CommentEntity saved = commentRepository.save(c);

    post.setCommentCount(post.getCommentCount() + 1);
    postRepository.save(post);

    return toResponse(saved);
  }

  @PostMapping("/{commentId}/like")
  public CommentResponse toggleLike(
      @PathVariable long postId,
      @PathVariable long commentId,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final CommentEntity comment = commentRepository.findById(commentId)
        .orElseThrow(() -> new IllegalArgumentException("Comment not found"));

    final CommentReactionId id = new CommentReactionId(commentId, principal.getUserId());
    if (commentLikeRepository.existsById(id)) {
      commentLikeRepository.deleteById(id);
      comment.setLikeCount(Math.max(0, comment.getLikeCount() - 1));
    } else {
      // remove dislike if present
      if (commentDislikeRepository.existsById(id)) {
        commentDislikeRepository.deleteById(id);
        comment.setDislikeCount(Math.max(0, comment.getDislikeCount() - 1));
      }
      commentLikeRepository.save(new CommentLikeEntity(id));
      comment.setLikeCount(comment.getLikeCount() + 1);
    }

    final CommentEntity saved = commentRepository.save(comment);
    return toResponse(saved);
  }

  @PostMapping("/{commentId}/dislike")
  public CommentResponse toggleDislike(
      @PathVariable long postId,
      @PathVariable long commentId,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final CommentEntity comment = commentRepository.findById(commentId)
        .orElseThrow(() -> new IllegalArgumentException("Comment not found"));

    final CommentReactionId id = new CommentReactionId(commentId, principal.getUserId());
    if (commentDislikeRepository.existsById(id)) {
      commentDislikeRepository.deleteById(id);
      comment.setDislikeCount(Math.max(0, comment.getDislikeCount() - 1));
    } else {
      // remove like if present
      if (commentLikeRepository.existsById(id)) {
        commentLikeRepository.deleteById(id);
        comment.setLikeCount(Math.max(0, comment.getLikeCount() - 1));
      }
      commentDislikeRepository.save(new CommentDislikeEntity(id));
      comment.setDislikeCount(comment.getDislikeCount() + 1);
    }

    final CommentEntity saved = commentRepository.save(comment);
    return toResponse(saved);
  }

  private CommentResponse toResponse(CommentEntity c) {
    final UserEntity author = userRepository.findById(c.getAuthorId()).orElse(null);
    final String authorUsername = author == null ? "user" : author.getUsername();
    final String authorPhotoUrl = author == null ? null : author.getPhotoUrl();
    final String authorThemeKey = author == null ? null : author.getThemeKey();
    final Integer authorThemeSeedColor = author == null ? null : author.getThemeSeedColor();

    final List<Long> likedBy = commentLikeRepository.findUserIdsWhoLiked(c.getId());
    final List<Long> dislikedBy = commentDislikeRepository.findUserIdsWhoDisliked(c.getId());

    return new CommentResponse(
        c.getId(),
        c.getPostId(),
        c.getAuthorId(),
        authorUsername,
        authorPhotoUrl,
        authorThemeKey,
        authorThemeSeedColor,
        c.getText(),
        c.getType(),
        c.getMediaUrl(),
        c.getCreatedAt(),
        c.getLikeCount(),
        likedBy,
        c.getParentCommentId(),
        c.getDislikeCount(),
        dislikedBy);
  }
}
