package com.friends.backend.follow;

import com.friends.backend.block.UserBlockId;
import com.friends.backend.block.UserBlockRepository;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import com.friends.backend.security.UserPrincipal;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/follows")
public class FollowController {
  private final UserFollowRepository userFollowRepository;
  private final UserRepository userRepository;
  private final UserBlockRepository userBlockRepository;

  public FollowController(
      UserFollowRepository userFollowRepository,
      UserRepository userRepository,
      UserBlockRepository userBlockRepository) {
    this.userFollowRepository = userFollowRepository;
    this.userRepository = userRepository;
    this.userBlockRepository = userBlockRepository;
  }

  private void ensureNotBlocked(long a, long b) {
    if (userBlockRepository.existsById(new UserBlockId(a, b))
        || userBlockRepository.existsById(new UserBlockId(b, a))) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Blocked");
    }
  }

  @GetMapping("/followers")
  public List<Long> myFollowers(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return userFollowRepository.findFollowerIds(principal.getUserId());
  }

  @GetMapping("/following")
  public List<Long> myFollowing(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return userFollowRepository.findFollowingIds(principal.getUserId());
  }

  @PostMapping("/{userId}")
  public ResponseEntity<Void> follow(@PathVariable long userId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    if (principal.getUserId() == userId) {
      return ResponseEntity.noContent().build();
    }

    ensureNotBlocked(principal.getUserId(), userId);

    final UserEntity target = userRepository.findById(userId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

    final UserFollowId id = new UserFollowId(principal.getUserId(), userId);
    if (!userFollowRepository.existsById(id)) {
      final boolean isPrivate = Boolean.TRUE.equals(target.getIsPrivateAccount());
      userFollowRepository.save(new UserFollowEntity(id, isPrivate ? "pending" : "accepted"));
    }
    return ResponseEntity.noContent().build();
  }

  @DeleteMapping("/{userId}")
  public ResponseEntity<Void> unfollow(@PathVariable long userId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserFollowId id = new UserFollowId(principal.getUserId(), userId);
    userFollowRepository.deleteById(id);
    return ResponseEntity.noContent().build();
  }

  @GetMapping("/{userId}/exists")
  public boolean isFollowing(@PathVariable long userId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return userFollowRepository.existsAccepted(principal.getUserId(), userId);
  }

  @GetMapping("/{userId}/requested")
  public boolean isRequested(@PathVariable long userId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserFollowId id = new UserFollowId(principal.getUserId(), userId);
    final UserFollowEntity row = userFollowRepository.findById(id).orElse(null);
    if (row == null) return false;
    final String st = row.getStatus() == null ? "" : row.getStatus().trim().toLowerCase();
    return st.equals("pending");
  }

  @GetMapping("/requests/incoming")
  public List<Long> incomingRequests(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return userFollowRepository.findIncomingRequestFollowerIds(principal.getUserId());
  }

  @GetMapping("/requests/outgoing")
  public List<Long> outgoingRequests(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return userFollowRepository.findOutgoingRequestFollowingIds(principal.getUserId());
  }

  @PostMapping("/requests/{followerId}/accept")
  public ResponseEntity<Void> acceptRequest(@PathVariable long followerId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    ensureNotBlocked(principal.getUserId(), followerId);
    final UserFollowId id = new UserFollowId(followerId, principal.getUserId());
    final UserFollowEntity row = userFollowRepository.findById(id)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Request not found"));
    final String st = row.getStatus() == null ? "" : row.getStatus().trim().toLowerCase();
    if (st.equals("pending")) {
      row.setStatus("accepted");
      userFollowRepository.save(row);
    }
    return ResponseEntity.noContent().build();
  }

  @DeleteMapping("/requests/{followerId}")
  public ResponseEntity<Void> declineRequest(@PathVariable long followerId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    ensureNotBlocked(principal.getUserId(), followerId);

    final UserFollowId incoming = new UserFollowId(followerId, principal.getUserId());
    if (userFollowRepository.existsById(incoming)) {
      userFollowRepository.deleteById(incoming);
      return ResponseEntity.noContent().build();
    }

    final UserFollowId outgoing = new UserFollowId(principal.getUserId(), followerId);
    if (userFollowRepository.existsById(outgoing)) {
      userFollowRepository.deleteById(outgoing);
    }
    return ResponseEntity.noContent().build();
  }
}
