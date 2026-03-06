package com.friends.backend.user;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "users")
public class UserEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, unique = true)
  private String email;

  @Column(nullable = false, unique = true, length = 50)
  private String username;

  @Column(name = "password_hash", nullable = false)
  private String passwordHash;

  @Column(name = "first_name")
  private String firstName;

  @Column(name = "last_name")
  private String lastName;

  private Integer age;

  @Column(name = "photo_url", columnDefinition = "TEXT")
  private String photoUrl;

  @Column(name = "background_image_url", columnDefinition = "TEXT")
  private String backgroundImageUrl;

  @Column(name = "theme_key", length = 40)
  private String themeKey;

  @Column(name = "theme_seed_color")
  private Integer themeSeedColor;

  @Column(columnDefinition = "TEXT")
  private String bio;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @Column(name = "is_online", nullable = false)
  private Boolean isOnline = false;

  @Column(name = "last_active_at")
  private Instant lastActiveAt;

  @Column(name = "is_private_account", nullable = false)
  private Boolean isPrivateAccount = false;

  @Column(name = "comment_policy", nullable = false)
  private String commentPolicy = "everyone";

  @Column(name = "is_official", nullable = false)
  private Boolean isOfficial = false;

  @Column(name = "badge_type", length = 32)
  private String badgeType;

  @PrePersist
  void onCreate() {
    final Instant now = Instant.now();
    createdAt = now;
    updatedAt = now;
  }

  @PreUpdate
  void onUpdate() {
    updatedAt = Instant.now();
  }

  public Long getId() {
    return id;
  }

  public String getEmail() {
    return email;
  }

  public void setEmail(String email) {
    this.email = email;
  }

  public String getUsername() {
    return username;
  }

  public void setUsername(String username) {
    this.username = username;
  }

  public String getPasswordHash() {
    return passwordHash;
  }

  public void setPasswordHash(String passwordHash) {
    this.passwordHash = passwordHash;
  }

  public String getFirstName() {
    return firstName;
  }

  public void setFirstName(String firstName) {
    this.firstName = firstName;
  }

  public String getLastName() {
    return lastName;
  }

  public void setLastName(String lastName) {
    this.lastName = lastName;
  }

  public Integer getAge() {
    return age;
  }

  public void setAge(Integer age) {
    this.age = age;
  }

  public String getPhotoUrl() {
    return photoUrl;
  }

  public void setPhotoUrl(String photoUrl) {
    this.photoUrl = photoUrl;
  }

  public String getBackgroundImageUrl() {
    return backgroundImageUrl;
  }

  public void setBackgroundImageUrl(String backgroundImageUrl) {
    this.backgroundImageUrl = backgroundImageUrl;
  }

  public String getThemeKey() {
    return themeKey;
  }

  public void setThemeKey(String themeKey) {
    this.themeKey = themeKey;
  }

  public Integer getThemeSeedColor() {
    return themeSeedColor;
  }

  public void setThemeSeedColor(Integer themeSeedColor) {
    this.themeSeedColor = themeSeedColor;
  }

  public String getBio() {
    return bio;
  }

  public void setBio(String bio) {
    this.bio = bio;
  }

  public Boolean getIsOnline() {
    return isOnline;
  }

  public void setIsOnline(Boolean isOnline) {
    this.isOnline = isOnline;
  }

  public Instant getLastActiveAt() {
    return lastActiveAt;
  }

  public void setLastActiveAt(Instant lastActiveAt) {
    this.lastActiveAt = lastActiveAt;
  }

  public Boolean getIsPrivateAccount() {
    return isPrivateAccount;
  }

  public void setIsPrivateAccount(Boolean isPrivateAccount) {
    this.isPrivateAccount = isPrivateAccount;
  }

  public String getCommentPolicy() {
    return commentPolicy;
  }

  public void setCommentPolicy(String commentPolicy) {
    this.commentPolicy = commentPolicy;
  }

  public Boolean getIsOfficial() {
    return isOfficial;
  }

  public void setIsOfficial(Boolean isOfficial) {
    this.isOfficial = isOfficial;
  }

  public String getBadgeType() {
    return badgeType;
  }

  public void setBadgeType(String badgeType) {
    this.badgeType = badgeType;
  }
}
