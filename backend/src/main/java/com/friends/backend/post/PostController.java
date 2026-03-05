package com.friends.backend.post;

import com.friends.backend.post.dto.CreatePostRequest;
import com.friends.backend.post.dto.PostResponse;
import com.friends.backend.post.dto.UpdatePostRequest;
import com.friends.backend.common.PagedResponse;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import jakarta.validation.Valid;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/posts")
public class PostController {
  private final PostRepository postRepository;
  private final PostLikeRepository postLikeRepository;
  private final UserRepository userRepository;

  public PostController(PostRepository postRepository, PostLikeRepository postLikeRepository, UserRepository userRepository) {
    this.postRepository = postRepository;
    this.postLikeRepository = postLikeRepository;
    this.userRepository = userRepository;
  }

  @GetMapping
  public List<PostResponse> recent(
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit) {
    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));
    final List<PostEntity> posts = postRepository.findByArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(
        PageRequest.of(safePage, safeLimit));
    return posts.stream().map(this::toResponse).toList();
  }

  @GetMapping("/paged")
  public PagedResponse<PostResponse> recentPaged(
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit) {
    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));

    // Fetch one extra item to determine hasMore.
    final List<PostEntity> rows = postRepository.findByArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(
        PageRequest.of(safePage, safeLimit + 1));

    final boolean hasMore = rows.size() > safeLimit;
    final List<PostEntity> pageRows = hasMore ? rows.subList(0, safeLimit) : rows;
    final List<PostResponse> items = pageRows.stream().map(this::toResponse).toList();

    return new PagedResponse<>(items, hasMore, hasMore ? safePage + 1 : null, null);
  }

  @GetMapping("/by-author")
  public List<PostResponse> byAuthor(
      @RequestParam(name = "authorId") long authorId,
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit) {
    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));
    final List<PostEntity> posts = postRepository
        .findByAuthorIdAndArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(authorId,
            PageRequest.of(safePage, safeLimit));
    return posts.stream().map(this::toResponse).toList();
  }

  @GetMapping("/by-author/paged")
  public PagedResponse<PostResponse> byAuthorPaged(
      @RequestParam(name = "authorId") long authorId,
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit) {
    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));

    final List<PostEntity> rows = postRepository
        .findByAuthorIdAndArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(authorId,
            PageRequest.of(safePage, safeLimit + 1));

    final boolean hasMore = rows.size() > safeLimit;
    final List<PostEntity> pageRows = hasMore ? rows.subList(0, safeLimit) : rows;
    final List<PostResponse> items = pageRows.stream().map(this::toResponse).toList();

    return new PagedResponse<>(items, hasMore, hasMore ? safePage + 1 : null, null);
  }

  @GetMapping("/{postId}")
  public PostResponse byId(@PathVariable long postId) {
    final PostEntity post = postRepository.findById(postId)
        .orElseThrow(() -> new IllegalArgumentException("Post not found"));
    if (post.getDeletedAt() != null) {
      throw new IllegalArgumentException("Post is deleted");
    }
    return toResponse(post);
  }

  @GetMapping("/archived")
  public List<PostResponse> myArchived(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final List<PostEntity> posts = postRepository
        .findTop200ByAuthorIdAndArchivedAtIsNotNullAndDeletedAtIsNullOrderByArchivedAtDesc(principal.getUserId());
    return posts.stream().map(this::toResponse).toList();
  }

  @GetMapping("/count")
  public Map<String, Long> countByAuthor(
      @RequestParam(name = "authorId") long authorId) {
    final long count = postRepository.countByAuthorIdAndArchivedAtIsNullAndDeletedAtIsNull(authorId);
    return Map.of("count", count);
  }

  @PostMapping
  public PostResponse create(@Valid @RequestBody CreatePostRequest req, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserEntity me = userRepository.findById(principal.getUserId())
        .orElseThrow(() -> new IllegalArgumentException("User not found"));

    final PostEntity p = new PostEntity();
    p.setAuthorId(me.getId());
    p.setText(req.text.trim());
    p.setMediaUrl(req.mediaUrl == null || req.mediaUrl.trim().isEmpty() ? null : req.mediaUrl.trim());
    final String mt = req.mediaType == null || req.mediaType.trim().isEmpty() ? "text" : req.mediaType.trim();
    p.setMediaType(mt);

    final PostEntity saved = postRepository.save(p);
    return toResponse(saved);
  }

  @PatchMapping("/{postId}")
  public PostResponse update(
      @PathVariable long postId,
      @Valid @RequestBody UpdatePostRequest req,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final PostEntity post = postRepository.findById(postId)
        .orElseThrow(() -> new IllegalArgumentException("Post not found"));
    if (!post.getAuthorId().equals(principal.getUserId())) {
      throw new IllegalArgumentException("Only the author can edit this post");
    }
    if (post.getDeletedAt() != null) {
      throw new IllegalArgumentException("Post is deleted");
    }

    post.setText(req.text.trim());
    return toResponse(postRepository.save(post));
  }

  @PostMapping("/{postId}/archive")
  public ResponseEntity<Void> archive(@PathVariable long postId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final PostEntity post = postRepository.findById(postId)
        .orElseThrow(() -> new IllegalArgumentException("Post not found"));
    if (!post.getAuthorId().equals(principal.getUserId())) {
      throw new IllegalArgumentException("Only the author can archive this post");
    }
    if (post.getDeletedAt() != null) {
      throw new IllegalArgumentException("Post is deleted");
    }
    post.setArchivedAt(Instant.now());
    postRepository.save(post);
    return ResponseEntity.noContent().build();
  }

  @PostMapping("/{postId}/restore")
  public ResponseEntity<Void> restore(@PathVariable long postId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final PostEntity post = postRepository.findById(postId)
        .orElseThrow(() -> new IllegalArgumentException("Post not found"));
    if (!post.getAuthorId().equals(principal.getUserId())) {
      throw new IllegalArgumentException("Only the author can restore this post");
    }
    if (post.getDeletedAt() != null) {
      throw new IllegalArgumentException("Post is deleted");
    }
    post.setArchivedAt(null);
    postRepository.save(post);
    return ResponseEntity.noContent().build();
  }

  @DeleteMapping("/{postId}")
  public ResponseEntity<Void> delete(@PathVariable long postId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final PostEntity post = postRepository.findById(postId)
        .orElseThrow(() -> new IllegalArgumentException("Post not found"));
    if (!post.getAuthorId().equals(principal.getUserId())) {
      throw new IllegalArgumentException("Only the author can delete this post");
    }
    post.setDeletedAt(Instant.now());
    postRepository.save(post);
    return ResponseEntity.noContent().build();
  }

  @PostMapping("/{postId}/like")
  public PostResponse toggleLike(@PathVariable long postId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final PostEntity post = postRepository.findById(postId)
        .orElseThrow(() -> new IllegalArgumentException("Post not found"));

    final PostLikeId id = new PostLikeId(postId, principal.getUserId());
    if (postLikeRepository.existsById(id)) {
      postLikeRepository.deleteById(id);
      post.setLikeCount(Math.max(0, post.getLikeCount() - 1));
    } else {
      postLikeRepository.save(new PostLikeEntity(id));
      post.setLikeCount(post.getLikeCount() + 1);
    }
    final PostEntity saved = postRepository.save(post);
    return toResponse(saved);
  }

  @PostMapping("/{postId}/share")
  public ResponseEntity<Void> share(@PathVariable long postId) {
    final PostEntity post = postRepository.findById(postId)
        .orElseThrow(() -> new IllegalArgumentException("Post not found"));
    post.setShareCount(post.getShareCount() + 1);
    postRepository.save(post);
    return ResponseEntity.noContent().build();
  }

  @PostMapping("/{postId}/pin/{commentId}")
  public ResponseEntity<Void> pin(@PathVariable long postId, @PathVariable long commentId) {
    final PostEntity post = postRepository.findById(postId)
        .orElseThrow(() -> new IllegalArgumentException("Post not found"));
    post.setPinnedCommentId(commentId);
    postRepository.save(post);
    return ResponseEntity.noContent().build();
  }

  @PostMapping("/{postId}/unpin")
  public ResponseEntity<Void> unpin(@PathVariable long postId) {
    final PostEntity post = postRepository.findById(postId)
        .orElseThrow(() -> new IllegalArgumentException("Post not found"));
    post.setPinnedCommentId(null);
    postRepository.save(post);
    return ResponseEntity.noContent().build();
  }

  private PostResponse toResponse(PostEntity p) {
    final UserEntity author = userRepository.findById(p.getAuthorId()).orElse(null);
    final String authorUsername = author == null ? "user" : author.getUsername();
    final String authorPhotoUrl = author == null ? null : author.getPhotoUrl();
    final List<Long> likedBy = postLikeRepository.findUserIdsWhoLiked(p.getId());
    return new PostResponse(
        p.getId(),
        p.getAuthorId(),
        authorUsername,
        authorPhotoUrl,
        p.getText(),
        p.getMediaUrl(),
        p.getMediaType(),
        p.getCreatedAt(),
        p.getLikeCount(),
        likedBy,
        p.getCommentCount(),
        p.getShareCount(),
        p.getPinnedCommentId(),
        p.getArchivedAt(),
        p.getDeletedAt());
  }
}
