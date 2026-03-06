package com.friends.backend.mute;

import com.friends.backend.security.UserPrincipal;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/mutes")
public class MuteController {
  private final UserMuteRepository userMuteRepository;

  public MuteController(UserMuteRepository userMuteRepository) {
    this.userMuteRepository = userMuteRepository;
  }

  @GetMapping
  public List<Long> myMuted(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return userMuteRepository.findMutedIds(principal.getUserId());
  }

  @PostMapping("/{userId}")
  public ResponseEntity<Void> mute(@PathVariable long userId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    if (principal.getUserId() == userId) {
      return ResponseEntity.noContent().build();
    }
    final UserMuteId id = new UserMuteId(principal.getUserId(), userId);
    if (!userMuteRepository.existsById(id)) {
      userMuteRepository.save(new UserMuteEntity(id));
    }
    return ResponseEntity.noContent().build();
  }

  @DeleteMapping("/{userId}")
  public ResponseEntity<Void> unmute(@PathVariable long userId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserMuteId id = new UserMuteId(principal.getUserId(), userId);
    userMuteRepository.deleteById(id);
    return ResponseEntity.noContent().build();
  }

  @GetMapping("/{userId}/exists")
  public boolean isMuted(@PathVariable long userId, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserMuteId id = new UserMuteId(principal.getUserId(), userId);
    return userMuteRepository.existsById(id);
  }
}
