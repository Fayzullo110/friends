package com.friends.backend.notification;

import com.friends.backend.notification.dto.CreateNotificationRequest;
import com.friends.backend.notification.dto.NotificationResponse;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {
  private final NotificationRepository notificationRepository;
  private final UserRepository userRepository;

  public NotificationController(NotificationRepository notificationRepository, UserRepository userRepository) {
    this.notificationRepository = notificationRepository;
    this.userRepository = userRepository;
  }

  @GetMapping
  public List<NotificationResponse> myNotifications(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return notificationRepository.findTop50ByToUserIdOrderByCreatedAtDesc(principal.getUserId())
        .stream()
        .map(this::toResponse)
        .toList();
  }

  @GetMapping("/unread")
  public List<NotificationResponse> myUnread(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return notificationRepository.findTop50ByToUserIdAndIsReadFalseOrderByCreatedAtDesc(principal.getUserId())
        .stream()
        .map(this::toResponse)
        .toList();
  }

  @PostMapping("/mark-all-read")
  public ResponseEntity<Void> markAllAsRead(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    notificationRepository.markAllAsRead(principal.getUserId());
    return ResponseEntity.noContent().build();
  }

  @PostMapping
  public NotificationResponse create(@Valid @RequestBody CreateNotificationRequest req, Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    if (req.toUserId == null) {
      throw new IllegalArgumentException("toUserId is required");
    }
    if (req.toUserId == principal.getUserId()) {
      throw new IllegalArgumentException("Cannot notify yourself");
    }

    final NotificationEntity n = new NotificationEntity();
    n.setToUserId(req.toUserId);
    n.setFromUserId(principal.getUserId());
    n.setType(req.type.trim());
    n.setPostId(req.postId);
    n.setIsRead(false);

    return toResponse(notificationRepository.save(n));
  }

  private NotificationResponse toResponse(NotificationEntity n) {
    final UserEntity from = userRepository.findById(n.getFromUserId()).orElse(null);
    final String fromUsername = from == null ? "user" : from.getUsername();
    return new NotificationResponse(
        n.getId(),
        n.getType(),
        n.getFromUserId(),
        fromUsername,
        n.getPostId(),
        n.getCreatedAt(),
        Boolean.TRUE.equals(n.getIsRead()));
  }
}
