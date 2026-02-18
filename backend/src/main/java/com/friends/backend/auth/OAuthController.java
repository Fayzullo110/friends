package com.friends.backend.auth;

import com.friends.backend.auth.dto.AuthResponse;
import com.friends.backend.auth.dto.OAuthFacebookRequest;
import com.friends.backend.auth.dto.OAuthGoogleRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth/oauth")
public class OAuthController {
  private final OAuthService oAuthService;

  public OAuthController(OAuthService oAuthService) {
    this.oAuthService = oAuthService;
  }

  @PostMapping("/google")
  public ResponseEntity<AuthResponse> google(@Valid @RequestBody OAuthGoogleRequest req) {
    return ResponseEntity.ok(oAuthService.loginWithGoogleIdToken(req.idToken));
  }

  @PostMapping("/facebook")
  public ResponseEntity<AuthResponse> facebook(@Valid @RequestBody OAuthFacebookRequest req) {
    return ResponseEntity.ok(oAuthService.loginWithFacebookAccessToken(req.accessToken));
  }
}
