package com.friends.backend.user;

import com.friends.backend.auth.AuthService;
import com.friends.backend.auth.dto.UserResponse;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.dto.UserSearchResponse;
import com.friends.backend.user.dto.ChangePasswordRequest;
import com.friends.backend.user.dto.UpdateMeRequest;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {
  private final UserService userService;
  private final UserRepository userRepository;

  public UserController(UserService userService, UserRepository userRepository) {
    this.userService = userService;
    this.userRepository = userRepository;
  }

  @GetMapping("/me")
  public UserResponse me(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserEntity user = userService.requireById(principal.getUserId());
    return AuthService.toUserResponse(user);
  }

  @GetMapping("/{id}")
  public UserResponse byId(@PathVariable long id) {
    final UserEntity user = userService.requireById(id);
    return AuthService.toUserResponse(user);
  }

  @GetMapping
  public List<UserResponse> byIds(@RequestParam("ids") String ids) {
    final List<Long> parsed = Arrays.stream(ids.split(","))
        .map(String::trim)
        .filter(s -> !s.isEmpty())
        .map(Long::parseLong)
        .toList();

    return userService.requireByIds(parsed).stream()
        .map(AuthService::toUserResponse)
        .collect(Collectors.toList());
  }

  @GetMapping("/search")
  public List<UserSearchResponse> search(@RequestParam("q") String q) {
    final String query = q == null ? "" : q.trim();
    if (query.isEmpty()) return List.of();
    return userRepository.search(query).stream()
        .limit(50)
        .map(u -> new UserSearchResponse(u.getId(), u.getEmail(), u.getUsername(), u.getPhotoUrl()))
        .toList();
  }

  @GetMapping("/recent")
  public List<UserSearchResponse> recent(Authentication authentication) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    return userRepository.listRecent(principal.getUserId()).stream()
        .limit(50)
        .map(u -> new UserSearchResponse(u.getId(), u.getEmail(), u.getUsername(), u.getPhotoUrl()))
        .toList();
  }

  @GetMapping("/username-available")
  public boolean usernameAvailable(@RequestParam("u") String u) {
    final String username = u == null ? "" : u.trim();
    if (username.isEmpty()) return false;
    return !userRepository.existsByUsername(username);
  }

  @PostMapping("/me/change-password")
  public ResponseEntity<Void> changePassword(
      Authentication authentication,
      @Valid @RequestBody ChangePasswordRequest request) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    userService.changePassword(principal.getUserId(), request.oldPassword, request.newPassword);
    return ResponseEntity.noContent().build();
  }

  @PatchMapping("/me")
  public UserResponse updateMe(
      Authentication authentication,
      @Valid @RequestBody UpdateMeRequest request) {
    final UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
    final UserEntity updated = userService.updateMe(principal.getUserId(), request);
    return AuthService.toUserResponse(updated);
  }
}
