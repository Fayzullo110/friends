package com.friends.backend.friend;

import com.friends.backend.block.UserBlockId;
import com.friends.backend.block.UserBlockRepository;
import com.friends.backend.friend.dto.FriendRequestResponse;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/friends")
public class FriendController {
  private final FriendRequestRepository friendRequestRepository;
  private final FriendRepository friendRepository;
  private final UserRepository userRepository;
  private final UserBlockRepository userBlockRepository;

  public FriendController(
      FriendRequestRepository friendRequestRepository,
      FriendRepository friendRepository,
      UserRepository userRepository,
      UserBlockRepository userBlockRepository) {
    this.friendRequestRepository = friendRequestRepository;
    this.friendRepository = friendRepository;
    this.userRepository = userRepository;
    this.userBlockRepository = userBlockRepository;
  }

  @GetMapping
  public List<Long> myFriends(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return friendRepository.findFriendIds(principal.getUserId());
  }

  @GetMapping("/requests/incoming")
  public List<FriendRequestResponse> incoming(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return friendRequestRepository.findTop50ByToUserIdAndStatusOrderByCreatedAtDesc(
            principal.getUserId(), "pending")
        .stream()
        .map(this::toResponse)
        .toList();
  }

  @PostMapping("/requests/{toUserId}")
  public ResponseEntity<Void> sendRequest(@PathVariable long toUserId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final long meId = principal.getUserId();
    if (meId == toUserId) return ResponseEntity.noContent().build();

    // Block checks both directions.
    if (userBlockRepository.existsById(new UserBlockId(meId, toUserId))
        || userBlockRepository.existsById(new UserBlockId(toUserId, meId))) {
      return ResponseEntity.status(403).build();
    }

    // Already friends -> ok.
    if (friendRepository.existsById(new FriendId(meId, toUserId))) {
      return ResponseEntity.noContent().build();
    }

    // Already pending.
    if (friendRequestRepository.existsByFromUserIdAndToUserIdAndStatus(meId, toUserId, "pending")) {
      return ResponseEntity.noContent().build();
    }

    // If there is an incoming pending request from them -> accept it automatically.
    final List<FriendRequestEntity> incoming = friendRequestRepository
        .findTop50ByToUserIdAndStatusOrderByCreatedAtDesc(meId, "pending")
        .stream()
        .filter(r -> r.getFromUserId() == toUserId)
        .toList();
    if (!incoming.isEmpty()) {
      final FriendRequestEntity r = incoming.get(0);
      r.setStatus("accepted");
      friendRequestRepository.save(r);
      createFriendPair(meId, toUserId);
      return ResponseEntity.noContent().build();
    }

    FriendRequestEntity r = new FriendRequestEntity();
    r.setFromUserId(meId);
    r.setToUserId(toUserId);
    r.setStatus("pending");
    friendRequestRepository.save(r);

    return ResponseEntity.noContent().build();
  }

  @PostMapping("/requests/{requestId}/accept")
  public ResponseEntity<Void> accept(@PathVariable long requestId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final FriendRequestEntity req = friendRequestRepository.findById(requestId)
        .orElseThrow(() -> new IllegalArgumentException("Request not found"));

    if (req.getToUserId() != principal.getUserId()) {
      return ResponseEntity.status(403).build();
    }

    if (!"pending".equals(req.getStatus())) {
      return ResponseEntity.noContent().build();
    }

    req.setStatus("accepted");
    friendRequestRepository.save(req);
    createFriendPair(req.getFromUserId(), req.getToUserId());
    return ResponseEntity.noContent().build();
  }

  @PostMapping("/requests/{requestId}/reject")
  public ResponseEntity<Void> reject(@PathVariable long requestId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final FriendRequestEntity req = friendRequestRepository.findById(requestId)
        .orElseThrow(() -> new IllegalArgumentException("Request not found"));

    if (req.getToUserId() != principal.getUserId()) {
      return ResponseEntity.status(403).build();
    }

    if (!"pending".equals(req.getStatus())) {
      return ResponseEntity.noContent().build();
    }

    req.setStatus("rejected");
    friendRequestRepository.save(req);
    return ResponseEntity.noContent().build();
  }

  private void createFriendPair(long userA, long userB) {
    if (userA == userB) return;
    final FriendId ab = new FriendId(userA, userB);
    final FriendId ba = new FriendId(userB, userA);
    if (!friendRepository.existsById(ab)) {
      friendRepository.save(new FriendEntity(ab));
    }
    if (!friendRepository.existsById(ba)) {
      friendRepository.save(new FriendEntity(ba));
    }
  }

  private FriendRequestResponse toResponse(@NotNull FriendRequestEntity r) {
    final UserEntity from = userRepository.findById(r.getFromUserId()).orElse(null);
    final String fromUsername = from == null ? "user" : from.getUsername();
    return new FriendRequestResponse(
        r.getId(),
        r.getFromUserId(),
        r.getToUserId(),
        fromUsername,
        r.getCreatedAt(),
        r.getStatus());
  }
}
