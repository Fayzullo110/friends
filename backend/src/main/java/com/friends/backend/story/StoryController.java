package com.friends.backend.story;

import com.friends.backend.security.UserPrincipal;
import com.friends.backend.story.dto.CreateStoryRequest;
import com.friends.backend.story.dto.StoryResponse;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import jakarta.validation.Valid;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/stories")
public class StoryController {
  private final StoryRepository storyRepository;
  private final StorySeenRepository storySeenRepository;
  private final StoryLikeRepository storyLikeRepository;
  private final UserRepository userRepository;

  public StoryController(
      StoryRepository storyRepository,
      StorySeenRepository storySeenRepository,
      StoryLikeRepository storyLikeRepository,
      UserRepository userRepository) {
    this.storyRepository = storyRepository;
    this.storySeenRepository = storySeenRepository;
    this.storyLikeRepository = storyLikeRepository;
    this.userRepository = userRepository;
  }

  @GetMapping
  public List<StoryResponse> active() {
    final Instant now = Instant.now();
    return storyRepository.findTop200ByExpiresAtAfterOrderByExpiresAtAscCreatedAtDesc(now)
        .stream()
        .map(this::toResponse)
        .toList();
  }

  @GetMapping("/user/{authorId}")
  public List<StoryResponse> activeByUser(@PathVariable long authorId) {
    final Instant now = Instant.now();
    return storyRepository.findTop200ByAuthorIdAndExpiresAtAfterOrderByExpiresAtAscCreatedAtDesc(authorId, now)
        .stream()
        .map(this::toResponse)
        .toList();
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

    return toResponse(storyRepository.save(s));
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

  private StoryResponse toResponse(StoryEntity s) {
    final String authorUsername = userRepository.findById(s.getAuthorId())
        .map(UserEntity::getUsername)
        .orElse("user");

    final List<Long> seenBy = storySeenRepository.findUserIdsWhoSaw(s.getId());

    final List<Long> likedBy = storyLikeRepository.findUserIdsWhoLiked(s.getId());

    return new StoryResponse(
        s.getId(),
        s.getAuthorId(),
        authorUsername,
        s.getMediaUrl(),
        s.getMediaType(),
        s.getText(),
        s.getCreatedAt(),
        s.getExpiresAt(),
        seenBy,
        likedBy,
        s.getMusicTitle(),
        s.getMusicArtist(),
        s.getMusicUrl());
  }
}
