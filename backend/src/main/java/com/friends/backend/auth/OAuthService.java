package com.friends.backend.auth;

import com.friends.backend.auth.dto.AuthResponse;
import com.friends.backend.security.JwtService;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import java.net.URI;
import java.security.SecureRandom;
import java.util.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.core.ParameterizedTypeReference;

@Service
public class OAuthService {
  private final UserRepository userRepository;
  private final PasswordEncoder passwordEncoder;
  private final JwtService jwtService;
  private final RestTemplate restTemplate = new RestTemplate();

  private final Set<String> googleClientIds;
  private final String facebookAppId;
  private final String facebookAppSecret;

  private static final SecureRandom RNG = new SecureRandom();

  public OAuthService(
      UserRepository userRepository,
      PasswordEncoder passwordEncoder,
      JwtService jwtService,
      @Value("${app.oauth.googleClientIds:}") String googleClientIds,
      @Value("${app.oauth.facebookAppId:}") String facebookAppId,
      @Value("${app.oauth.facebookAppSecret:}") String facebookAppSecret) {
    this.userRepository = userRepository;
    this.passwordEncoder = passwordEncoder;
    this.jwtService = jwtService;

    final Set<String> ids = new HashSet<>();
    if (googleClientIds != null) {
      for (final String part : googleClientIds.split(",")) {
        final String trimmed = part.trim();
        if (!trimmed.isEmpty()) ids.add(trimmed);
      }
    }
    this.googleClientIds = Collections.unmodifiableSet(ids);
    this.facebookAppId = facebookAppId == null ? "" : facebookAppId.trim();
    this.facebookAppSecret = facebookAppSecret == null ? "" : facebookAppSecret.trim();
  }

  public AuthResponse loginWithGoogleIdToken(String idToken) {
    if (googleClientIds.isEmpty()) {
      throw new IllegalStateException("Google OAuth is not configured (app.oauth.googleClientIds)");
    }

    final Map<String, Object> tokenInfo = getJson(
        URI.create("https://oauth2.googleapis.com/tokeninfo?id_token=" + encode(idToken)));

    final String aud = asString(tokenInfo.get("aud"));
    if (aud == null || !googleClientIds.contains(aud)) {
      throw new IllegalArgumentException("Invalid Google token audience");
    }

    final String email = normalizeEmail(asString(tokenInfo.get("email")));
    final String emailVerified = asString(tokenInfo.get("email_verified"));
    if (email == null || email.isEmpty()) {
      throw new IllegalArgumentException("Google account has no email");
    }
    if (emailVerified != null && emailVerified.equalsIgnoreCase("false")) {
      throw new IllegalArgumentException("Google email is not verified");
    }

    final String name = asString(tokenInfo.get("name"));
    final String picture = asString(tokenInfo.get("picture"));

    return loginOrCreateUser(email, name, picture);
  }

  public AuthResponse loginWithFacebookAccessToken(String accessToken) {
    if (facebookAppId.isEmpty() || facebookAppSecret.isEmpty()) {
      throw new IllegalStateException("Facebook OAuth is not configured (app.oauth.facebookAppId/appSecret)");
    }

    // 1) Validate token via debug_token
    final String appAccessToken = facebookAppId + "|" + facebookAppSecret;
    final Map<String, Object> debug = getJson(
        URI.create("https://graph.facebook.com/debug_token?input_token="
            + encode(accessToken)
            + "&access_token="
            + encode(appAccessToken)));

    final Object dataObj = debug.get("data");
    if (!(dataObj instanceof Map<?, ?> data)) {
      throw new IllegalArgumentException("Invalid Facebook debug response");
    }
    final Boolean isValid = asBool(data.get("is_valid"));
    if (isValid == null || !isValid) {
      throw new IllegalArgumentException("Invalid Facebook access token");
    }
    final String appId = asString(data.get("app_id"));
    if (appId == null || !appId.equals(facebookAppId)) {
      throw new IllegalArgumentException("Facebook token app_id mismatch");
    }

    // 2) Fetch profile
    final Map<String, Object> me = getJson(
        URI.create("https://graph.facebook.com/me?fields=id,name,email,picture.type(large)&access_token="
            + encode(accessToken)));

    final String email = normalizeEmail(asString(me.get("email")));
    if (email == null || email.isEmpty()) {
      throw new IllegalArgumentException("Facebook account has no email. Ensure you request the email permission.");
    }

    String name = asString(me.get("name"));
    String pictureUrl = null;
    final Object pic = me.get("picture");
    if (pic instanceof Map<?, ?> picMap) {
      final Object d = picMap.get("data");
      if (d instanceof Map<?, ?> dm) {
        final Object u = dm.get("url");
        if (u != null) pictureUrl = u.toString();
      }
    }

    return loginOrCreateUser(email, name, pictureUrl);
  }

  private AuthResponse loginOrCreateUser(String email, String fullName, String pictureUrl) {
    final Optional<UserEntity> maybe = userRepository.findByEmail(email);
    final UserEntity user;
    if (maybe.isPresent()) {
      user = maybe.get();
      boolean changed = false;
      if ((user.getPhotoUrl() == null || user.getPhotoUrl().isEmpty()) && pictureUrl != null && !pictureUrl.isEmpty()) {
        user.setPhotoUrl(pictureUrl);
        changed = true;
      }
      if (changed) userRepository.save(user);
    } else {
      user = new UserEntity();
      user.setEmail(email);
      user.setUsername(generateUniqueUsername(email, fullName));
      user.setPasswordHash(passwordEncoder.encode(randomSecret()));

      if (fullName != null && !fullName.trim().isEmpty()) {
        final String[] parts = fullName.trim().split("\\s+", 2);
        user.setFirstName(parts.length > 0 ? parts[0] : null);
        user.setLastName(parts.length > 1 ? parts[1] : null);
      }
      if (pictureUrl != null && !pictureUrl.trim().isEmpty()) {
        user.setPhotoUrl(pictureUrl.trim());
      }

      userRepository.save(user);
    }

    final String token = jwtService.generateToken(user.getId(), user.getUsername());
    return new AuthResponse(token, AuthService.toUserResponse(user));
  }

  private String generateUniqueUsername(String email, String fullName) {
    String base = null;
    if (fullName != null && !fullName.trim().isEmpty()) {
      base = fullName.trim().toLowerCase().replaceAll("[^a-z0-9]", "");
    }
    if (base == null || base.isEmpty()) {
      base = email.split("@", 2)[0].toLowerCase().replaceAll("[^a-z0-9]", "");
    }
    if (base.isEmpty()) base = "user";
    if (base.length() > 20) base = base.substring(0, 20);

    String candidate = base;
    int attempts = 0;
    while (userRepository.existsByUsername(candidate)) {
      attempts++;
      candidate = base + randomDigits(4);
      if (attempts > 20) {
        candidate = "user" + randomDigits(8);
      }
    }
    return candidate;
  }

  private static String randomDigits(int n) {
    final StringBuilder sb = new StringBuilder(n);
    for (int i = 0; i < n; i++) {
      sb.append((char) ('0' + RNG.nextInt(10)));
    }
    return sb.toString();
  }

  private static String randomSecret() {
    final byte[] bytes = new byte[32];
    RNG.nextBytes(bytes);
    return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
  }

  private Map<String, Object> getJson(URI uri) {
    final HttpHeaders headers = new HttpHeaders();
    headers.setAccept(List.of(MediaType.APPLICATION_JSON));
    final HttpEntity<Void> entity = new HttpEntity<>(headers);

    final ResponseEntity<Map<String, Object>> resp = restTemplate.exchange(
        uri,
        HttpMethod.GET,
        entity,
        new ParameterizedTypeReference<Map<String, Object>>() {});
    if (!resp.getStatusCode().is2xxSuccessful() || resp.getBody() == null) {
      throw new IllegalArgumentException("OAuth verification failed");
    }
    return resp.getBody();
  }

  private static String normalizeEmail(String email) {
    if (email == null) return null;
    final String trimmed = email.trim().toLowerCase();
    return trimmed.isEmpty() ? null : trimmed;
  }

  private static String asString(Object o) {
    return o == null ? null : o.toString();
  }

  private static Boolean asBool(Object o) {
    if (o == null) return null;
    if (o instanceof Boolean b) return b;
    final String s = o.toString();
    if (s.equalsIgnoreCase("true")) return true;
    if (s.equalsIgnoreCase("false")) return false;
    return null;
  }

  private static String encode(String s) {
    if (s == null) return "";
    return java.net.URLEncoder.encode(s, java.nio.charset.StandardCharsets.UTF_8);
  }
}
