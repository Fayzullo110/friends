package com.friends.backend.user;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.security.crypto.password.PasswordEncoder;
import com.friends.backend.user.dto.UpdateMeRequest;

@Service
public class UserService {
  private final UserRepository userRepository;
  private final PasswordEncoder passwordEncoder;

  public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
    this.userRepository = userRepository;
    this.passwordEncoder = passwordEncoder;
  }

  public UserEntity requireById(long id) {
    return userRepository.findById(id).orElseThrow(() -> new IllegalArgumentException("User not found"));
  }

  public List<UserEntity> requireByIds(List<Long> ids) {
    final List<UserEntity> users = userRepository.findAllById(ids);
    if (users.size() != ids.size()) {
      final Map<Long, UserEntity> byId = users.stream()
          .collect(Collectors.toMap(UserEntity::getId, Function.identity()));

      final List<Long> missing = ids.stream()
          .filter(id -> !byId.containsKey(id))
          .toList();

      throw new IllegalArgumentException("Users not found: " + missing);
    }
    return users;
  }

  public void changePassword(long userId, String oldPassword, String newPassword) {
    final UserEntity user = requireById(userId);
    if (!passwordEncoder.matches(oldPassword, user.getPasswordHash())) {
      throw new IllegalArgumentException("Old password is incorrect");
    }
    user.setPasswordHash(passwordEncoder.encode(newPassword));
    userRepository.save(user);
  }

  public UserEntity updateMe(long userId, UpdateMeRequest req) {
    final UserEntity user = requireById(userId);

    if (req.username != null) {
      final String username = req.username.trim();
      if (username.isEmpty()) {
        throw new IllegalArgumentException("Username cannot be empty");
      }
      if (!username.equals(user.getUsername()) && userRepository.existsByUsername(username)) {
        throw new IllegalArgumentException("Username already in use");
      }
      user.setUsername(username);
    }

    if (req.bio != null) {
      final String bio = req.bio.trim();
      user.setBio(bio.isEmpty() ? null : bio);
    }

    if (req.photoUrl != null) {
      final String url = req.photoUrl.trim();
      user.setPhotoUrl(url.isEmpty() ? null : url);
    }

    if (req.backgroundImageUrl != null) {
      final String url = req.backgroundImageUrl.trim();
      user.setBackgroundImageUrl(url.isEmpty() ? null : url);
    }

    if (req.themeKey != null) {
      final String key = req.themeKey.trim();
      user.setThemeKey(key.isEmpty() ? null : key);
    }

    if (req.themeSeedColor != null) {
      user.setThemeSeedColor(req.themeSeedColor);
    }

    return userRepository.save(user);
  }
}
