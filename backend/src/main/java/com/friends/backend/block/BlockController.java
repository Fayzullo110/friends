package com.friends.backend.block;

import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import com.friends.backend.security.UserPrincipal;

@RestController
@RequestMapping("/api/blocks")
public class BlockController {
  private final UserBlockRepository userBlockRepository;

  public BlockController(UserBlockRepository userBlockRepository) {
    this.userBlockRepository = userBlockRepository;
  }

  @GetMapping
  public List<Long> myBlocked(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return userBlockRepository.findBlockedIds(principal.getUserId());
  }

  @PostMapping("/{userId}")
  public ResponseEntity<Void> block(@PathVariable long userId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    if (principal.getUserId() == userId) {
      return ResponseEntity.noContent().build();
    }
    final UserBlockId id = new UserBlockId(principal.getUserId(), userId);
    if (!userBlockRepository.existsById(id)) {
      userBlockRepository.save(new UserBlockEntity(id));
    }
    return ResponseEntity.noContent().build();
  }

  @DeleteMapping("/{userId}")
  public ResponseEntity<Void> unblock(@PathVariable long userId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserBlockId id = new UserBlockId(principal.getUserId(), userId);
    userBlockRepository.deleteById(id);
    return ResponseEntity.noContent().build();
  }

  @GetMapping("/{userId}/exists")
  public boolean isBlocked(@PathVariable long userId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserBlockId id = new UserBlockId(principal.getUserId(), userId);
    return userBlockRepository.existsById(id);
  }

  @GetMapping("/by/{userId}/exists")
  public boolean hasBlockedMe(@PathVariable long userId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserBlockId id = new UserBlockId(userId, principal.getUserId());
    return userBlockRepository.existsById(id);
  }
}
