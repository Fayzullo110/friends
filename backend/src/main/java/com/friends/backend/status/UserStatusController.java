package com.friends.backend.status;

import com.friends.backend.security.UserPrincipal;
import com.friends.backend.status.dto.CreateStatusRequest;
import com.friends.backend.status.dto.UserStatusResponse;
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
@RequestMapping("/api/statuses")
public class UserStatusController {
  private final UserStatusRepository userStatusRepository;
  private final UserStatusSeenRepository userStatusSeenRepository;
  private final UserRepository userRepository;

  public UserStatusController(
      UserStatusRepository userStatusRepository,
      UserStatusSeenRepository userStatusSeenRepository,
      UserRepository userRepository) {
    this.userStatusRepository = userStatusRepository;
    this.userStatusSeenRepository = userStatusSeenRepository;
    this.userRepository = userRepository;
  }

  @GetMapping
  public List<UserStatusResponse> active() {
    final Instant now = Instant.now();
    return userStatusRepository.findTop200ByExpiresAtAfterOrderByExpiresAtAscCreatedAtDesc(now)
        .stream()
        .map(this::toResponse)
        .toList();
  }

  @GetMapping("/me")
  public ResponseEntity<UserStatusResponse> myActive(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final Instant now = Instant.now();
    final List<UserStatusEntity> list = userStatusRepository
        .findTop1ByUserIdAndExpiresAtAfterOrderByExpiresAtAscCreatedAtDesc(principal.getUserId(), now);
    if (list.isEmpty()) return ResponseEntity.noContent().build();
    return ResponseEntity.ok(toResponse(list.get(0)));
  }

  @PostMapping
  public UserStatusResponse create(@Valid @RequestBody CreateStatusRequest req, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserEntity me = userRepository.findById(principal.getUserId())
        .orElseThrow(() -> new IllegalArgumentException("User not found"));

    final UserStatusEntity s = new UserStatusEntity();
    s.setUserId(me.getId());
    s.setText(req.text.trim());
    s.setEmoji(req.emoji);
    s.setMusicTitle(req.musicTitle);
    s.setMusicArtist(req.musicArtist);
    s.setMusicUrl(req.musicUrl);
    s.setExpiresAt(Instant.now().plus(24, ChronoUnit.HOURS));

    return toResponse(userStatusRepository.save(s));
  }

  @PostMapping("/{statusId}/seen")
  public ResponseEntity<Void> markSeen(@PathVariable long statusId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserStatusSeenId id = new UserStatusSeenId(statusId, principal.getUserId());
    if (!userStatusSeenRepository.existsById(id)) {
      userStatusSeenRepository.save(new UserStatusSeenEntity(id));
    }
    return ResponseEntity.noContent().build();
  }

  @DeleteMapping("/{statusId}")
  public ResponseEntity<Void> delete(@PathVariable long statusId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserStatusEntity status = userStatusRepository.findById(statusId)
        .orElseThrow(() -> new IllegalArgumentException("Status not found"));
    if (!status.getUserId().equals(principal.getUserId())) {
      throw new IllegalArgumentException("Only the owner can delete this status");
    }
    userStatusRepository.deleteById(statusId);
    return ResponseEntity.noContent().build();
  }

  private UserStatusResponse toResponse(UserStatusEntity s) {
    final UserEntity user = userRepository.findById(s.getUserId())
        .orElse(null);
    final String username = user == null ? "user" : user.getUsername();
    final String photoUrl = user == null ? null : user.getPhotoUrl();

    final List<Long> seenBy = userStatusSeenRepository.findUserIdsWhoSaw(s.getId());

    return new UserStatusResponse(
        s.getId(),
        s.getUserId(),
        username,
        photoUrl,
        s.getText(),
        s.getEmoji(),
        s.getMusicTitle(),
        s.getMusicArtist(),
        s.getMusicUrl(),
        s.getCreatedAt(),
        s.getExpiresAt(),
        seenBy);
  }
}
