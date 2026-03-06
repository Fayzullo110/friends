package com.friends.backend.user;

import com.friends.backend.auth.AuthService;
import com.friends.backend.auth.dto.UserResponse;
import com.friends.backend.block.UserBlockRepository;
import com.friends.backend.common.TrustSafetyUtils;
import com.friends.backend.follow.UserFollowRepository;
import com.friends.backend.friend.FriendRepository;
import com.friends.backend.mute.UserMuteRepository;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.dto.ChangePasswordRequest;
import com.friends.backend.user.dto.UpdateMeRequest;
import com.friends.backend.user.dto.UserSearchResponse;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {
  private final UserService userService;
  private final UserRepository userRepository;
  private final UserMuteRepository userMuteRepository;
  private final UserBlockRepository userBlockRepository;
  private final UserFollowRepository userFollowRepository;
  private final FriendRepository friendRepository;

  public UserController(
      UserService userService,
      UserRepository userRepository,
      UserMuteRepository userMuteRepository,
      UserBlockRepository userBlockRepository,
      UserFollowRepository userFollowRepository,
      FriendRepository friendRepository) {
    this.userService = userService;
    this.userRepository = userRepository;
    this.userMuteRepository = userMuteRepository;
    this.userBlockRepository = userBlockRepository;
    this.userFollowRepository = userFollowRepository;
    this.friendRepository = friendRepository;
  }

  @GetMapping("/me")
  public UserResponse me(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserEntity user = userService.requireById(principal.getUserId());
    return AuthService.toUserResponse(user);
  }

  @GetMapping("/{id}")
  public UserResponse byId(@PathVariable long id) {
    final UserEntity user = userService.requireById(id);
    return AuthService.toUserResponse(user);
  }

  @GetMapping
  public List<UserResponse> byIds(@RequestParam("ids") String ids) {
    final List<Long> parsed = Arrays.stream(ids.split(","))
        .map(String::trim)
        .filter(s -> !s.isEmpty())
        .map(Long::parseLong)
        .toList();

    return userService.requireByIds(parsed).stream()
        .map(AuthService::toUserResponse)
        .collect(Collectors.toList());
  }

  @GetMapping("/search")
  public List<UserSearchResponse> search(@RequestParam("q") String q) {
    final String query = q == null ? "" : q.trim();
    if (query.isEmpty()) return List.of();
    return userRepository.search(query).stream()
        .limit(50)
        .map(u -> new UserSearchResponse(u.getId(), u.getEmail(), u.getUsername(), u.getPhotoUrl()))
        .toList();
  }

  @GetMapping("/recent")
  public List<UserSearchResponse> recent(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return userRepository.listRecent(principal.getUserId()).stream()
        .limit(50)
        .map(u -> new UserSearchResponse(u.getId(), u.getEmail(), u.getUsername(), u.getPhotoUrl()))
        .toList();
  }

  @GetMapping("/suggested")
  public List<UserSearchResponse> suggested(
      @RequestParam(name = "limit", defaultValue = "50") int limit,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final long meId = principal.getUserId();
    final int safeLimit = Math.min(100, Math.max(1, limit));

    final Set<Long> excluded = new HashSet<>(
        TrustSafetyUtils.excludedUserIds(meId, userMuteRepository, userBlockRepository));
    excluded.add(meId);

    final Set<Long> myFriends = new HashSet<>(friendRepository.findFriendIds(meId));
    excluded.addAll(myFriends);

    final Set<Long> myFollowing = new HashSet<>(userFollowRepository.findFollowingIds(meId));
    excluded.addAll(myFollowing);
    excluded.addAll(userFollowRepository.findOutgoingRequestFollowingIds(meId));

    // Friends of friends
    final Map<Long, Integer> score = new HashMap<>();
    if (!myFriends.isEmpty()) {
      final List<Long> fof = friendRepository.findFriendIdsForUsers(new ArrayList<>(myFriends));
      for (final Long uid : fof) {
        if (uid == null) continue;
        if (excluded.contains(uid)) continue;
        score.merge(uid, 1, (a, b) -> a + b);
      }
    }

    final List<Long> top = score.entrySet().stream()
        .sorted((a, b) -> Integer.compare(b.getValue(), a.getValue()))
        .limit(safeLimit)
        .map(Map.Entry::getKey)
        .toList();

    final List<UserEntity> users = new ArrayList<>(userRepository.findAllById(top));
    final Set<Long> seen = new HashSet<>();
    for (final UserEntity u : users) {
      if (u != null && u.getId() != null) {
        seen.add(u.getId());
      }
    }

    // Fallback: recent users
    if (users.size() < safeLimit) {
      for (final UserEntity u : userRepository.listRecent(meId)) {
        if (u == null || u.getId() == null) continue;
        if (excluded.contains(u.getId())) continue;
        if (seen.contains(u.getId())) continue;
        users.add(u);
        seen.add(u.getId());
        if (users.size() >= safeLimit) break;
      }
    }

    return users.stream()
        .filter(u -> u != null && u.getId() != null)
        .limit(safeLimit)
        .map(u -> new UserSearchResponse(u.getId(), u.getEmail(), u.getUsername(), u.getPhotoUrl()))
        .toList();
  }

  @GetMapping("/username-available")
  public boolean usernameAvailable(@RequestParam("u") String u) {
    final String username = u == null ? "" : u.trim();
    if (username.isEmpty()) return false;
    return !userRepository.existsByUsername(username);
  }

  @PostMapping("/me/change-password")
  public ResponseEntity<Void> changePassword(
      Authentication authentication,
      @Valid @RequestBody ChangePasswordRequest request) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    userService.changePassword(principal.getUserId(), request.oldPassword, request.newPassword);
    return ResponseEntity.noContent().build();
  }

  @PatchMapping("/me")
  public UserResponse updateMe(
      Authentication authentication,
      @Valid @RequestBody UpdateMeRequest request) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserEntity updated = userService.updateMe(principal.getUserId(), request);
    return AuthService.toUserResponse(updated);
  }
}
