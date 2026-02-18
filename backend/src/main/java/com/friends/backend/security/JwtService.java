package com.friends.backend.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.io.DecodingException;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import java.security.Key;
import java.time.Instant;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class JwtService {
  private final Key signingKey;
  private final long expirationSeconds;

  public JwtService(
      @Value("${app.jwt.secret}") String secret,
      @Value("${app.jwt.expirationSeconds}") long expirationSeconds) {
    // Accept both raw string and base64. If not base64, fall back to raw bytes.
    Key key;
    try {
      final byte[] decoded = Decoders.BASE64.decode(secret);
      key = Keys.hmacShaKeyFor(decoded);
    } catch (DecodingException | IllegalArgumentException ex) {
      key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }
    this.signingKey = key;
    this.expirationSeconds = expirationSeconds;
  }

  public String generateToken(long userId, String username) {
    final Instant now = Instant.now();
    final Instant exp = now.plusSeconds(expirationSeconds);

    return Jwts.builder()
        .setSubject(String.valueOf(userId))
        .setIssuedAt(Date.from(now))
        .setExpiration(Date.from(exp))
        .addClaims(Map.of("username", username))
        .signWith(signingKey, SignatureAlgorithm.HS256)
        .compact();
  }

  public Claims parseClaims(String token) {
    return Jwts.parserBuilder().setSigningKey(signingKey).build().parseClaimsJws(token).getBody();
  }

  public long getUserId(String token) {
    final Claims claims = parseClaims(token);
    return Long.parseLong(claims.getSubject());
  }
}
