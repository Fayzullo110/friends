package com.friends.backend.notification.prefs;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "notification_preferences")
public class NotificationPreferencesEntity {
  @Id
  @Column(name = "user_id", nullable = false)
  private Long userId;

  @Column(name = "notify_likes", nullable = false)
  private Boolean notifyLikes = true;

  @Column(name = "notify_comments", nullable = false)
  private Boolean notifyComments = true;

  @Column(name = "notify_friend_requests", nullable = false)
  private Boolean notifyFriendRequests = true;

  @Column(name = "notify_friend_accepted", nullable = false)
  private Boolean notifyFriendAccepted = true;

  @Column(name = "notify_follows", nullable = false)
  private Boolean notifyFollows = true;

  @Column(name = "digest_enabled", nullable = false)
  private Boolean digestEnabled = false;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  public NotificationPreferencesEntity() {}

  public NotificationPreferencesEntity(long userId) {
    this.userId = userId;
  }

  public Long getUserId() {
    return userId;
  }

  public void setUserId(Long userId) {
    this.userId = userId;
  }

  public Boolean getNotifyLikes() {
    return notifyLikes;
  }

  public void setNotifyLikes(Boolean notifyLikes) {
    this.notifyLikes = notifyLikes;
  }

  public Boolean getNotifyComments() {
    return notifyComments;
  }

  public void setNotifyComments(Boolean notifyComments) {
    this.notifyComments = notifyComments;
  }

  public Boolean getNotifyFriendRequests() {
    return notifyFriendRequests;
  }

  public void setNotifyFriendRequests(Boolean notifyFriendRequests) {
    this.notifyFriendRequests = notifyFriendRequests;
  }

  public Boolean getNotifyFriendAccepted() {
    return notifyFriendAccepted;
  }

  public void setNotifyFriendAccepted(Boolean notifyFriendAccepted) {
    this.notifyFriendAccepted = notifyFriendAccepted;
  }

  public Boolean getNotifyFollows() {
    return notifyFollows;
  }

  public void setNotifyFollows(Boolean notifyFollows) {
    this.notifyFollows = notifyFollows;
  }

  public Boolean getDigestEnabled() {
    return digestEnabled;
  }

  public void setDigestEnabled(Boolean digestEnabled) {
    this.digestEnabled = digestEnabled;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public void setUpdatedAt(Instant updatedAt) {
    this.updatedAt = updatedAt;
  }
}
