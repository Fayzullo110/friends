package com.friends.backend.user.admin;

import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import com.friends.backend.user.admin.dto.UpdateUserBadgeRequest;
import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/admin/users")
public class AdminUserBadgeController {
  private final UserRepository userRepository;
  private final Set<Long> adminUserIds;

  public AdminUserBadgeController(
      UserRepository userRepository,
      @Value("${app.admin.userIds:}") String adminUserIdsCsv) {
    this.userRepository = userRepository;
    final String[] parts = (adminUserIdsCsv == null || adminUserIdsCsv.trim().isEmpty())
        ? new String[0]
        : adminUserIdsCsv.split(",");
    this.adminUserIds = Arrays.stream(parts)
        .map(String::trim)
        .filter(s -> !s.isEmpty())
        .map(Long::parseLong)
        .collect(Collectors.toSet());
  }

  private void requireAdmin(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    if (!adminUserIds.contains(principal.getUserId())) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Forbidden");
    }
  }

  @PatchMapping("/{userId}/badge")
  public ResponseEntity<Void> updateBadge(
      @PathVariable long userId,
      @RequestBody UpdateUserBadgeRequest req,
      Authentication authentication) {
    requireAdmin(authentication);

    final UserEntity user = userRepository.findById(userId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

    if (req != null) {
      if (req.isOfficial != null) {
        user.setIsOfficial(req.isOfficial);
      }

      if (req.badgeType != null) {
        final String raw = req.badgeType.trim();
        if (raw.isEmpty()) {
          user.setBadgeType(null);
        } else {
          final String bt = raw.toLowerCase();
          if (!(bt.equals("owner") || bt.equals("creator") || bt.equals("brand"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid badgeType");
          }
          user.setBadgeType(bt);
        }
      }
    }

    userRepository.save(user);
    return ResponseEntity.noContent().build();
  }
}
