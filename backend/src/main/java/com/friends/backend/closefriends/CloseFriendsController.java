package com.friends.backend.closefriends;

import com.friends.backend.block.UserBlockId;
import com.friends.backend.block.UserBlockRepository;
import com.friends.backend.security.UserPrincipal;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/close-friends")
public class CloseFriendsController {
  private final CloseFriendRepository closeFriendRepository;
  private final UserBlockRepository userBlockRepository;

  public CloseFriendsController(
      CloseFriendRepository closeFriendRepository,
      UserBlockRepository userBlockRepository) {
    this.closeFriendRepository = closeFriendRepository;
    this.userBlockRepository = userBlockRepository;
  }

  @GetMapping
  public List<Long> list(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return closeFriendRepository.findCloseFriendIds(principal.getUserId());
  }

  @PostMapping("/{userId}")
  public ResponseEntity<Void> add(@PathVariable long userId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final long meId = principal.getUserId();
    if (meId == userId) return ResponseEntity.noContent().build();

    // Block checks both directions.
    if (userBlockRepository.existsById(new UserBlockId(meId, userId))
        || userBlockRepository.existsById(new UserBlockId(userId, meId))) {
      return ResponseEntity.status(403).build();
    }

    final CloseFriendId id = new CloseFriendId(meId, userId);
    if (!closeFriendRepository.existsById(id)) {
      closeFriendRepository.save(new CloseFriendEntity(id));
    }
    return ResponseEntity.noContent().build();
  }

  @DeleteMapping("/{userId}")
  public ResponseEntity<Void> remove(@PathVariable long userId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final long meId = principal.getUserId();
    final CloseFriendId id = new CloseFriendId(meId, userId);
    if (closeFriendRepository.existsById(id)) {
      closeFriendRepository.deleteById(id);
    }
    return ResponseEntity.noContent().build();
  }
}
