package com.friends.backend.notification.prefs;

import com.friends.backend.notification.prefs.dto.NotificationPreferencesResponse;
import com.friends.backend.notification.prefs.dto.UpdateNotificationPreferencesRequest;
import com.friends.backend.security.UserPrincipal;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notification-preferences")
public class NotificationPreferencesController {
  private final NotificationPreferencesRepository repo;

  public NotificationPreferencesController(NotificationPreferencesRepository repo) {
    this.repo = repo;
  }

  @GetMapping
  public NotificationPreferencesResponse get(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final NotificationPreferencesEntity row = repo.findById(principal.getUserId())
        .orElseGet(() -> repo.save(new NotificationPreferencesEntity(principal.getUserId())));
    return toResponse(row);
  }

  @PutMapping
  public NotificationPreferencesResponse update(
      @RequestBody UpdateNotificationPreferencesRequest req,
      Authentication authentication) {
    return applyUpdate(req, authentication);
  }

  @PatchMapping
  public NotificationPreferencesResponse patch(
      @RequestBody UpdateNotificationPreferencesRequest req,
      Authentication authentication) {
    return applyUpdate(req, authentication);
  }

  private NotificationPreferencesResponse applyUpdate(
      UpdateNotificationPreferencesRequest req,
      Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final NotificationPreferencesEntity row = repo.findById(principal.getUserId())
        .orElseGet(() -> new NotificationPreferencesEntity(principal.getUserId()));

    if (req != null) {
      if (req.notifyLikes != null) row.setNotifyLikes(req.notifyLikes);
      if (req.notifyComments != null) row.setNotifyComments(req.notifyComments);
      if (req.notifyFriendRequests != null) row.setNotifyFriendRequests(req.notifyFriendRequests);
      if (req.notifyFriendAccepted != null) row.setNotifyFriendAccepted(req.notifyFriendAccepted);
      if (req.notifyFollows != null) row.setNotifyFollows(req.notifyFollows);
      if (req.digestEnabled != null) row.setDigestEnabled(req.digestEnabled);
    }

    return toResponse(repo.save(row));
  }

  private NotificationPreferencesResponse toResponse(NotificationPreferencesEntity row) {
    return new NotificationPreferencesResponse(
        Boolean.TRUE.equals(row.getNotifyLikes()),
        Boolean.TRUE.equals(row.getNotifyComments()),
        Boolean.TRUE.equals(row.getNotifyFriendRequests()),
        Boolean.TRUE.equals(row.getNotifyFriendAccepted()),
        Boolean.TRUE.equals(row.getNotifyFollows()),
        Boolean.TRUE.equals(row.getDigestEnabled()));
  }
}
