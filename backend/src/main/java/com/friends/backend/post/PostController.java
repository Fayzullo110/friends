package com.friends.backend.post;

import com.friends.backend.block.UserBlockRepository;
import com.friends.backend.common.TrustSafetyUtils;
import com.friends.backend.follow.UserFollowRepository;
import com.friends.backend.mute.UserMuteRepository;
import com.friends.backend.post.dto.CreatePostRequest;
import com.friends.backend.post.dto.PostResponse;
import com.friends.backend.post.dto.UpdatePostRequest;
import com.friends.backend.common.PagedResponse;
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
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/posts")
public class PostController {
  private final PostRepository postRepository;
  private final PostLikeRepository postLikeRepository;
  private final UserRepository userRepository;

  private final UserMuteRepository userMuteRepository;
  private final UserBlockRepository userBlockRepository;
  private final UserFollowRepository userFollowRepository;

  public PostController(
      PostRepository postRepository,
      PostLikeRepository postLikeRepository,
      UserRepository userRepository,
      UserMuteRepository userMuteRepository,
      UserBlockRepository userBlockRepository,
      UserFollowRepository userFollowRepository) {
    this.postRepository = postRepository;
    this.postLikeRepository = postLikeRepository;
    this.userRepository = userRepository;
    this.userMuteRepository = userMuteRepository;
    this.userBlockRepository = userBlockRepository;
    this.userFollowRepository = userFollowRepository;
  }

  @GetMapping
  public List<PostResponse> recent(
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit,
      Authentication authentication) {
    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));

    final Long meId = TrustSafetyUtils.getUserIdOrNull(authentication);
    final Set<Long> excluded = TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository);

    final List<PostEntity> raw = postRepository.findByArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(
        PageRequest.of(safePage, safeLimit));

    final Set<Long> authorIds = raw.stream().map(PostEntity::getAuthorId).filter(Objects::nonNull).collect(Collectors.toSet());
    final Map<Long, UserEntity> usersById = userRepository.findAllById(authorIds).stream()
        .collect(Collectors.toMap(UserEntity::getId, u -> u));
    final Set<Long> myFollowingIds = meId == null
        ? Set.of()
        : new HashSet<>(userFollowRepository.findFollowingIds(meId));

    final List<PostEntity> posts = raw.stream()
        .filter(p -> p.getAuthorId() != null)
        .filter(p -> !excluded.contains(p.getAuthorId()))
        .filter(p -> TrustSafetyUtils.canSeePrivateUser(meId, p.getAuthorId(), usersById, myFollowingIds))
        .toList();

    return posts.stream().map(this::toResponse).toList();
  }

  @GetMapping("/paged")
  public PagedResponse<PostResponse> recentPaged(
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit,
      Authentication authentication) {
    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));

    // Fetch one extra item to determine hasMore.
    final Long meId = TrustSafetyUtils.getUserIdOrNull(authentication);
    final Set<Long> excluded = TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository);

    final List<PostEntity> rows = postRepository.findByArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(
        PageRequest.of(safePage, safeLimit + 1));

    final Set<Long> authorIds = rows.stream().map(PostEntity::getAuthorId).filter(Objects::nonNull).collect(Collectors.toSet());
    final Map<Long, UserEntity> usersById = userRepository.findAllById(authorIds).stream()
        .collect(Collectors.toMap(UserEntity::getId, u -> u));
    final Set<Long> myFollowingIds = meId == null
        ? Set.of()
        : new HashSet<>(userFollowRepository.findFollowingIds(meId));

    final List<PostEntity> filtered = rows.stream()
        .filter(p -> p.getAuthorId() != null)
        .filter(p -> !excluded.contains(p.getAuthorId()))
        .filter(p -> TrustSafetyUtils.canSeePrivateUser(meId, p.getAuthorId(), usersById, myFollowingIds))
        .toList();

    final boolean hasMore = filtered.size() > safeLimit;
    final List<PostEntity> pageRows = hasMore ? filtered.subList(0, safeLimit) : filtered;
    final List<PostResponse> items = pageRows.stream().map(this::toResponse).toList();

    return new PagedResponse<>(items, hasMore, hasMore ? safePage + 1 : null, null);
  }

  @GetMapping("/by-author")
  public List<PostResponse> byAuthor(
      @RequestParam(name = "authorId") long authorId,
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit,
      Authentication authentication) {
    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));

    final Long meId = TrustSafetyUtils.getUserIdOrNull(authentication);
    final Set<Long> excluded = TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository);
    if (excluded.contains(authorId)) {
      return List.of();
    }

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

    final List<PostEntity> posts = postRepository
        .findByAuthorIdAndArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(authorId,
            PageRequest.of(safePage, safeLimit));
    return posts.stream().map(this::toResponse).toList();
  }

  @GetMapping("/by-author/paged")
  public PagedResponse<PostResponse> byAuthorPaged(
      @RequestParam(name = "authorId") long authorId,
      @RequestParam(name = "page", defaultValue = "0") int page,
      @RequestParam(name = "limit", defaultValue = "100") int limit,
      Authentication authentication) {
    final int safePage = Math.max(0, page);
    final int safeLimit = Math.min(200, Math.max(1, limit));

    final Long meId = TrustSafetyUtils.getUserIdOrNull(authentication);
    final Set<Long> excluded = TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository);
    if (excluded.contains(authorId)) {
      return new PagedResponse<>(List.of(), false, null, null);
    }

    if (meId == null || meId != authorId) {
      final UserEntity author = userRepository.findById(authorId).orElse(null);
      if (author == null) {
        throw new IllegalArgumentException("User not found");
      }
      if (Boolean.TRUE.equals(author.getIsPrivateAccount())) {
        if (meId == null) {
          return new PagedResponse<>(List.of(), false, null, null);
        }
        final boolean follows = userFollowRepository.existsAccepted(meId, authorId);
        if (!follows) {
          return new PagedResponse<>(List.of(), false, null, null);
        }
      }
    }

    final List<PostEntity> rows = postRepository
        .findByAuthorIdAndArchivedAtIsNullAndDeletedAtIsNullOrderByCreatedAtDesc(authorId,
            PageRequest.of(safePage, safeLimit + 1));

    final boolean hasMore = rows.size() > safeLimit;
    final List<PostEntity> pageRows = hasMore ? rows.subList(0, safeLimit) : rows;
    final List<PostResponse> items = pageRows.stream().map(this::toResponse).toList();

    return new PagedResponse<>(items, hasMore, hasMore ? safePage + 1 : null, null);
  }

  @GetMapping("/{postId}")
  public PostResponse byId(@PathVariable long postId, Authentication authentication) {
    final PostEntity post = postRepository.findById(postId)
        .orElseThrow(() -> new IllegalArgumentException("Post not found"));
    if (post.getDeletedAt() != null) {
      throw new IllegalArgumentException("Post is deleted");
    }

    final Long meId = TrustSafetyUtils.getUserIdOrNull(authentication);
    final Long authorId = post.getAuthorId();
    if (authorId == null) {
      throw new IllegalArgumentException("Post not found");
    }

    final Set<Long> excluded = TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository);
    if (excluded.contains(authorId)) {
      throw new IllegalArgumentException("Post not found");
    }

    final UserEntity author = userRepository.findById(authorId).orElse(null);
    if (author == null) {
      throw new IllegalArgumentException("Post not found");
    }

    if (Boolean.TRUE.equals(author.getIsPrivateAccount())) {
      if (meId == null) {
        throw new IllegalArgumentException("Post not found");
      }
      if (meId != authorId && !userFollowRepository.existsAccepted(meId, authorId)) {
        throw new IllegalArgumentException("Post not found");
      }
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
