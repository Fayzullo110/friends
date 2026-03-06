package com.friends.backend.common;

import com.friends.backend.block.UserBlockRepository;
import com.friends.backend.mute.UserMuteRepository;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.UserEntity;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import org.springframework.security.core.Authentication;

public final class TrustSafetyUtils {
  private TrustSafetyUtils() {}

  public static Long getUserIdOrNull(Authentication authentication) {
    if (authentication == null) return null;
    final Object p = authentication.getPrincipal();
    if (!(p instanceof UserPrincipal principal)) return null;
    return principal.getUserId();
  }

  public static Set<Long> excludedUserIds(
      Long meId,
      UserMuteRepository userMuteRepository,
      UserBlockRepository userBlockRepository) {
    if (meId == null) return Set.of();
    final Set<Long> ids = new HashSet<>();
    ids.addAll(userMuteRepository.findMutedIds(meId));
    ids.addAll(userBlockRepository.findBlockedIds(meId));
    ids.addAll(userBlockRepository.findBlockerIds(meId));
    return ids;
  }

  public static boolean canSeePrivateUser(
      Long meId,
      long authorId,
      Map<Long, UserEntity> usersById,
      Set<Long> myFollowingIds) {
    if (meId != null && meId == authorId) return true;
    final UserEntity author = usersById.get(authorId);
    if (author == null) return false;
    final boolean isPrivate = Boolean.TRUE.equals(author.getIsPrivateAccount());
    if (!isPrivate) return true;
    if (meId == null) return false;
    return myFollowingIds.contains(authorId);
  }
}
