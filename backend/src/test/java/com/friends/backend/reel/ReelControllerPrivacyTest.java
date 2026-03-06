package com.friends.backend.reel;

import com.friends.backend.block.UserBlockRepository;
import com.friends.backend.follow.UserFollowRepository;
import com.friends.backend.mute.UserMuteRepository;
import com.friends.backend.security.UserPrincipal;
import com.friends.backend.user.UserEntity;
import com.friends.backend.user.UserRepository;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.server.ResponseStatusException;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

public class ReelControllerPrivacyTest {

  @Test
  void byId_privateAuthor_notFollower_forbidden() {
    final long meId = 10L;
    final long authorId = 20L;
    final long reelId = 30L;

    final ReelRepository reelRepository = mock(ReelRepository.class);
    final ReelLikeRepository reelLikeRepository = mock(ReelLikeRepository.class);
    final UserRepository userRepository = mock(UserRepository.class);
    final UserMuteRepository userMuteRepository = mock(UserMuteRepository.class);
    final UserBlockRepository userBlockRepository = mock(UserBlockRepository.class);
    final UserFollowRepository userFollowRepository = mock(UserFollowRepository.class);

    final ReelController c = new ReelController(
        reelRepository,
        reelLikeRepository,
        userRepository,
        userMuteRepository,
        userBlockRepository,
        userFollowRepository);

    final ReelEntity reel = mock(ReelEntity.class);
    when(reel.getId()).thenReturn(reelId);
    when(reel.getAuthorId()).thenReturn(authorId);
    when(reel.getDeletedAt()).thenReturn(null);

    final UserEntity author = new UserEntity();
    author.setIsPrivateAccount(true);
    author.setUsername("author");

    when(reelRepository.findById(reelId)).thenReturn(Optional.of(reel));
    when(userRepository.findById(authorId)).thenReturn(Optional.of(author));
    when(userMuteRepository.findMutedIds(meId)).thenReturn(List.of());
    when(userBlockRepository.findBlockedIds(meId)).thenReturn(List.of());
    when(userBlockRepository.findBlockerIds(meId)).thenReturn(List.of());
    when(userFollowRepository.existsAccepted(meId, authorId)).thenReturn(false);

    final Authentication authentication = Mockito.mock(Authentication.class);
    when(authentication.getPrincipal()).thenReturn(new UserPrincipal(meId));

    final ResponseStatusException ex = assertThrows(
        ResponseStatusException.class,
        () -> c.byId(reelId, authentication));

    assertEquals(HttpStatus.FORBIDDEN, ex.getStatusCode());
  }

  @Test
  void byId_privateAuthor_follower_allowed() {
    final long meId = 10L;
    final long authorId = 20L;
    final long reelId = 30L;

    final ReelRepository reelRepository = mock(ReelRepository.class);
    final ReelLikeRepository reelLikeRepository = mock(ReelLikeRepository.class);
    final UserRepository userRepository = mock(UserRepository.class);
    final UserMuteRepository userMuteRepository = mock(UserMuteRepository.class);
    final UserBlockRepository userBlockRepository = mock(UserBlockRepository.class);
    final UserFollowRepository userFollowRepository = mock(UserFollowRepository.class);

    final ReelController c = new ReelController(
        reelRepository,
        reelLikeRepository,
        userRepository,
        userMuteRepository,
        userBlockRepository,
        userFollowRepository);

    final ReelEntity reel = mock(ReelEntity.class);
    when(reel.getId()).thenReturn(reelId);
    when(reel.getAuthorId()).thenReturn(authorId);
    when(reel.getDeletedAt()).thenReturn(null);
    when(reel.getCaption()).thenReturn("");
    when(reel.getMediaUrl()).thenReturn(null);
    when(reel.getMediaType()).thenReturn("video");
    when(reel.getLikeCount()).thenReturn(0);
    when(reel.getCommentCount()).thenReturn(0);
    when(reel.getShareCount()).thenReturn(0);
    when(reel.getCreatedAt()).thenReturn(null);
    when(reel.getArchivedAt()).thenReturn(null);

    final UserEntity author = new UserEntity();
    author.setIsPrivateAccount(true);
    author.setUsername("author");

    when(reelRepository.findById(reelId)).thenReturn(Optional.of(reel));
    when(userRepository.findById(authorId)).thenReturn(Optional.of(author));
    when(userMuteRepository.findMutedIds(meId)).thenReturn(List.of());
    when(userBlockRepository.findBlockedIds(meId)).thenReturn(List.of());
    when(userBlockRepository.findBlockerIds(meId)).thenReturn(List.of());
    when(userFollowRepository.existsAccepted(meId, authorId)).thenReturn(true);
    when(reelLikeRepository.findUserIdsWhoLiked(anyLong())).thenReturn(List.of());

    final Authentication authentication = Mockito.mock(Authentication.class);
    when(authentication.getPrincipal()).thenReturn(new UserPrincipal(meId));

    assertDoesNotThrow(() -> c.byId(reelId, authentication));
  }
}
