package com.friends.backend.auth;

import com.friends.backend.auth.dto.AuthResponse;
import com.friends.backend.auth.dto.LoginRequest;
import com.friends.backend.auth.dto.SignupRequest;
import com.friends.backend.auth.dto.UserResponse;
import com.friends.backend.security.JwtService;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import java.util.Optional;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
  private final UserRepository userRepository;
  private final PasswordEncoder passwordEncoder;
  private final JwtService jwtService;

  public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtService jwtService) {
    this.userRepository = userRepository;
    this.passwordEncoder = passwordEncoder;
    this.jwtService = jwtService;
  }

  public AuthResponse signup(SignupRequest req) {
    final String email = req.email.trim().toLowerCase();
    final String username = req.username.trim();

    if (userRepository.existsByEmail(email)) {
      throw new IllegalArgumentException("Email already in use");
    }
    if (userRepository.existsByUsername(username)) {
      throw new IllegalArgumentException("Username already in use");
    }

    final UserEntity user = new UserEntity();
    user.setEmail(email);
    user.setUsername(username);
    user.setPasswordHash(passwordEncoder.encode(req.password));
    user.setFirstName(normalizeNullable(req.firstName));
    user.setLastName(normalizeNullable(req.lastName));
    user.setAge(req.age);

    final UserEntity saved = userRepository.save(user);
    final String token = jwtService.generateToken(saved.getId(), saved.getUsername());

    return new AuthResponse(token, toUserResponse(saved));
  }

  public AuthResponse login(LoginRequest req) {
    final String id = req.identifier.trim();

    final Optional<UserEntity> maybeUser = id.contains("@")
        ? userRepository.findByEmail(id.toLowerCase())
        : userRepository.findByUsername(id);

    final UserEntity user = maybeUser.orElseThrow(() -> new IllegalArgumentException("Invalid credentials"));

    if (!passwordEncoder.matches(req.password, user.getPasswordHash())) {
      throw new IllegalArgumentException("Invalid credentials");
    }

    final String token = jwtService.generateToken(user.getId(), user.getUsername());
    return new AuthResponse(token, toUserResponse(user));
  }

  public static UserResponse toUserResponse(UserEntity user) {
    return new UserResponse(
        user.getId(),
        user.getEmail(),
        user.getUsername(),
        user.getFirstName(),
        user.getLastName(),
        user.getAge(),
        user.getPhotoUrl(),
        user.getBio(),
        user.getBackgroundImageUrl(),
        user.getThemeKey(),
        user.getThemeSeedColor(),
        Boolean.TRUE.equals(user.getIsOnline()),
        user.getLastActiveAt() == null ? null : user.getLastActiveAt().toString());
  }

  private static String normalizeNullable(String value) {
    if (value == null) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty() ? null : trimmed;
  }
}
