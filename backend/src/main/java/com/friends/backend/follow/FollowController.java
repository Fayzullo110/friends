package com.friends.backend.follow;

import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import com.friends.backend.security.UserPrincipal;

@RestController
@RequestMapping("/api/follows")
public class FollowController {
  private final UserFollowRepository userFollowRepository;

  public FollowController(UserFollowRepository userFollowRepository) {
    this.userFollowRepository = userFollowRepository;
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
    final UserFollowId id = new UserFollowId(principal.getUserId(), userId);
    if (!userFollowRepository.existsById(id)) {
      userFollowRepository.save(new UserFollowEntity(id));
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
    final UserFollowId id = new UserFollowId(principal.getUserId(), userId);
    return userFollowRepository.existsById(id);
  }
}
