package com.friends.backend.notification.prefs.dto;

public class NotificationPreferencesResponse {
  public boolean notifyLikes;
  public boolean notifyComments;
  public boolean notifyFriendRequests;
  public boolean notifyFriendAccepted;
  public boolean notifyFollows;
  public boolean digestEnabled;

  public NotificationPreferencesResponse(
      boolean notifyLikes,
      boolean notifyComments,
      boolean notifyFriendRequests,
      boolean notifyFriendAccepted,
      boolean notifyFollows,
      boolean digestEnabled) {
    this.notifyLikes = notifyLikes;
    this.notifyComments = notifyComments;
    this.notifyFriendRequests = notifyFriendRequests;
    this.notifyFriendAccepted = notifyFriendAccepted;
    this.notifyFollows = notifyFollows;
    this.digestEnabled = digestEnabled;
  }
}
