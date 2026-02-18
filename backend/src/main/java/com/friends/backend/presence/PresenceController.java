package com.friends.backend.presence;

import com.friends.backend.presence.dto.PresenceUpdateRequest;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import jakarta.validation.Valid;
import java.time.Instant;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/presence")
public class PresenceController {
  private final UserRepository userRepository;

  public PresenceController(UserRepository userRepository) {
    this.userRepository = userRepository;
  }

  @PostMapping
  public ResponseEntity<Void> update(@Valid @RequestBody PresenceUpdateRequest req, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserEntity me = userRepository.findById(principal.getUserId())
        .orElseThrow(() -> new IllegalArgumentException("User not found"));

    me.setIsOnline(Boolean.TRUE.equals(req.online));
    me.setLastActiveAt(Instant.now());
    userRepository.save(me);

    return ResponseEntity.noContent().build();
  }
}
