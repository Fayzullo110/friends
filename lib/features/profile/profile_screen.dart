import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../models/app_user.dart';
import '../../models/post.dart';
import '../../models/reel.dart';
import '../../services/auth_service.dart';
import '../../services/block_service.dart';
import '../../services/chat_service.dart';
import '../../services/follow_service.dart';
import '../../services/post_service.dart';
import '../../services/reel_service.dart';
import '../../services/story_highlight_service.dart';
import '../../models/story_highlight.dart';
import '../../theme/ios_icons.dart';
import '../../theme/app_themes.dart';
import '../chat/chat_detail_screen.dart';
import '../post/post_viewer_screen.dart';
import '../reels/reels_screen.dart';
import '../../widgets/safe_network_image.dart';
import '../story/highlight_viewer_screen.dart';
import '../story/highlight_edit_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  _ProfileTabType _selectedTab = _ProfileTabType.grid;
  bool _isStartingChat = false;

  bool _isVideoUrl(String url) {
    final u = url.trim().toLowerCase();
    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.m4v') ||
        u.endsWith('.webm');
  }

  String _profileLink(AppUser user) {
    // Lightweight internal deep-link style string. Can be replaced with real web URL later.
    return 'friends://profile/${user.id}';
  }

  Future<void> _copyProfileLink(AppUser user) async {
    final link = _profileLink(user);
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile link copied')),
    );
  }

  Future<void> _shareProfile(AppUser user) async {
    final link = _profileLink(user);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(IOSIcons.shareUp),
                title: const Text('Share'),
                subtitle: Text(link),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await Share.share(
                      link,
                      subject: 'Friends profile',
                    );
                  } catch (_) {
                    await _copyProfileLink(user);
                  }
                },
              ),
              ListTile(
                leading: const Icon(IOSIcons.share),
                title: const Text('Copy link'),
                subtitle: Text(link),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _copyProfileLink(user);
                },
              ),
              ListTile(
                leading: const Icon(IOSIcons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<AppUser?> _loadUser() async {
    if (widget.userId == null) {
      return await AuthService.instance.api
          .getJson('/api/users/me', (json) => AppUser.fromJson(json));
    }

    final id = int.parse(widget.userId!);
    return await AuthService.instance.api
        .getJson('/api/users/$id', (json) => AppUser.fromJson(json));
  }

  Stream<List<AppUser>> _usersStreamFromIds(Stream<List<String>> idsStream) {
    return idsStream.asyncMap((ids) => _fetchUsersByIds(ids));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<AppUser?>(
      future: _loadUser(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        final user = snap.data;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('User not found')),
          );
        }

        final accent = AppThemes.seedFor(
          themeKey: user.themeKey,
          themeSeedColor: user.themeSeedColor,
        );

        final me = AuthService.instance.currentUser;
        final isOwnProfile = widget.userId == null || (me != null && me.id == user.id);

        return Scaffold(
          body: Stack(
            children: [
              // Background gradient (always visible behind)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        accent.withOpacity(0.22),
                        theme.scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
              // Background media
              if (user.backgroundImageUrl != null &&
                  user.backgroundImageUrl!.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 200,
                  child: _ProfileBackgroundMedia(
                    url: user.backgroundImageUrl!,
                    height: 200,
                    isVideo: _isVideoUrl(user.backgroundImageUrl!),
                  ),
                ),
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 500,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.none,
                      background: Container(
                        color: Colors.transparent,
                        child: Column(
                          children: [
                            const SizedBox(height: 150),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            alignment: Alignment.bottomRight,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: theme.scaffoldBackgroundColor,
                                                    width: 4,
                                                  ),
                                                ),
                                                child: SizedBox(
                                                  width: 92,
                                                  height: 92,
                                                  child: ClipOval(
                                                    child: (user.photoUrl != null &&
                                                            user.photoUrl!
                                                                .trim()
                                                                .isNotEmpty)
                                                        ? SafeNetworkImage(
                                                            url: user.photoUrl,
                                                            width: 92,
                                                            height: 92,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : Container(
                                                            color: accent.withOpacity(0.18),
                                                            alignment:
                                                                Alignment.center,
                                                            child: Text(
                                                              user.username
                                                                      .isNotEmpty
                                                                  ? user.username[0]
                                                                      .toUpperCase()
                                                                  : 'U',
                                                              style: TextStyle(
                                                                color: theme
                                                                    .colorScheme
                                                                    .onPrimaryContainer,
                                                                fontWeight:
                                                                    FontWeight.w800,
                                                                fontSize: 32,
                                                              ),
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ),
                                              if (isOwnProfile)
                                                const SizedBox.shrink(),
                                            ],
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  (user.displayName != null &&
                                                          user.displayName!
                                                              .trim()
                                                              .isNotEmpty)
                                                      ? user.displayName!
                                                      : user.username,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme.titleLarge
                                                      ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    height: 1.1,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: accent.withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(999),
                                                    border: Border.all(
                                                      color: accent.withOpacity(0.35),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    AppThemes.labelFor(
                                                      themeKey: user.themeKey,
                                                      themeSeedColor:
                                                          user.themeSeedColor,
                                                    ),
                                                    style: theme
                                                        .textTheme.labelSmall
                                                        ?.copyWith(
                                                      color: accent,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '@${user.username.toLowerCase().replaceAll(' ', '_')}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(
                                                    color: theme
                                                        .colorScheme.onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                if ((user.bio ?? '')
                                                    .trim()
                                                    .isNotEmpty)
                                                  Text(
                                                    user.bio!.trim(),
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme.bodyMedium
                                                        ?.copyWith(
                                                      color: theme.colorScheme
                                                          .onSurface
                                                          .withOpacity(0.8),
                                                      height: 1.25,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            StreamBuilder<int>(
                                              stream: PostService.instance
                                                  .watchPostCountByAuthor(
                                                authorId: user.id,
                                              ),
                                              builder: (context, snapshot) {
                                                final count =
                                                    snapshot.data ?? 0;
                                                return _ProfileStat(
                                                  label: 'Posts',
                                                  value: count.toString(),
                                                );
                                              },
                                            ),
                                            Container(
                                              height: 26,
                                              width: 1,
                                              color: theme.dividerColor,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 18),
                                            ),
                                            _FollowersStat(
                                              user: user,
                                              onTap: () {
                                                _showFollowListSheet(
                                                  context,
                                                  title: 'Followers',
                                                  usersStream:
                                                      _usersStreamFromIds(
                                                    FollowService.instance
                                                        .watchFollowers(
                                                            uid: user.id),
                                                  ),
                                                );
                                              },
                                            ),
                                            Container(
                                              height: 26,
                                              width: 1,
                                              color: theme.dividerColor,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 18),
                                            ),
                                            _FollowingStat(
                                              user: user,
                                              onTap: () {
                                                _showFollowListSheet(
                                                  context,
                                                  title: 'Following',
                                                  usersStream:
                                                      _usersStreamFromIds(
                                                    FollowService.instance
                                                        .watchFollowing(
                                                            uid: user.id),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (!isOwnProfile)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: _isStartingChat
                                                    ? null
                                                    : () async {
                                                  final meNow = AuthService
                                                      .instance.currentUser;
                                                  if (meNow == null) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Please log in to send a message.',
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  final eitherBlocked =
                                                      await BlockService
                                                              .instance
                                                              .isBlocked(
                                                            fromUserId:
                                                                meNow.id,
                                                            toUserId: user.id,
                                                          ) ||
                                                          await BlockService
                                                              .instance
                                                              .isBlocked(
                                                            fromUserId: user.id,
                                                            toUserId:
                                                                meNow.id,
                                                          );
                                                  if (eitherBlocked) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'You can\'t start a chat because there is a block between you.',
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  try {
                                                    if (mounted) {
                                                      setState(() {
                                                        _isStartingChat =
                                                            true;
                                                      });
                                                    }
                                                    final chatId =
                                                        await ChatService
                                                            .instance
                                                            .createOrGetDirectChat(
                                                      me: meNow,
                                                      other: user,
                                                    );
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    setState(() {
                                                      _isStartingChat =
                                                          false;
                                                    });
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ChatDetailScreen(
                                                          chatId: chatId,
                                                          title: user.username,
                                                          otherUserId: user.id,
                                                        ),
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    setState(() {
                                                      _isStartingChat =
                                                          false;
                                                    });
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Failed to start chat: $e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                icon: _isStartingChat
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                    : const Icon(
                                                        IOSIcons.chat,
                                                        size: 18,
                                                      ),
                                                label:
                                                    const Text('Message'),
                                                style:
                                                    OutlinedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                                  side: BorderSide(
                                                    color: theme
                                                        .colorScheme.outline,
                                                  ),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: StreamBuilder<bool>(
                                                stream: FollowService
                                                    .instance
                                                    .watchIsFollowing(
                                                  fromUserId: (me?.id ?? ''),
                                                  toUserId: user.id,
                                                ),
                                                builder:
                                                    (context, snapshot) {
                                                  final isFollowing =
                                                      snapshot.data ??
                                                          false;
                                                  return FilledButton(
                                                    onPressed: () async {
                                                      if (me == null) return;
                                                      try {
                                                        if (isFollowing) {
                                                          await FollowService
                                                              .instance
                                                              .unfollow(
                                                            fromUserId: me.id,
                                                            toUserId: user.id,
                                                          );
                                                        } else {
                                                          await FollowService
                                                              .instance
                                                              .follow(
                                                            fromUserId: me.id,
                                                            toUserId: user.id,
                                                          );
                                                        }
                                                      } catch (e) {
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                  'Error: $e'),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    style: FilledButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFFD4943A),
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        vertical: 12,
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(18),
                                                      ),
                                                    ),
                                                    child: Text(isFollowing
                                                        ? 'Following'
                                                        : 'Follow'),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (isOwnProfile)
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EditProfileScreen(
                                                    user: user,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              IOSIcons.editOutlined,
                                              size: 18,
                                            ),
                                            label: const Text('Edit Profile'),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                              side: BorderSide(
                                                color:
                                                    theme.colorScheme.outline,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _copyProfileLink(user),
                                              icon: const Icon(
                                                IOSIcons.attachFile,
                                                size: 18,
                                              ),
                                              label: const Text('Copy link'),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                ),
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _shareProfile(user),
                                              icon: const Icon(
                                                IOSIcons.shareUp,
                                                size: 18,
                                              ),
                                              label: const Text('Share'),
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                ),
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _HighlightsRow(
                              ownerId: user.id,
                              isOwnProfile: isOwnProfile,
                              accent: accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      color: theme.scaffoldBackgroundColor,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: _ProfileTabRow(
                        selected: _selectedTab,
                        onSelected: (tab) => setState(() => _selectedTab = tab),
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    child: Container(
                      color: theme.scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RefreshIndicator(
                        onRefresh: () async {
                          setState(() {});
                        },
                        child: StreamBuilder<List<Post>>(
                          stream: PostService.instance.watchPostsByAuthor(
                            authorId: user.id,
                          ),
                          builder: (context, snapshot) {
                            final isLoading =
                                snapshot.connectionState == ConnectionState.waiting;
                            final myPosts = snapshot.data ?? const <Post>[];
                          final mediaPosts = myPosts
                              .where((p) =>
                                  p.mediaUrl != null &&
                                  p.mediaUrl!.isNotEmpty &&
                                  p.mediaType != 'text')
                              .toList();
                          final textPosts = myPosts
                              .where((p) =>
                                  p.mediaUrl == null ||
                                  p.mediaUrl!.isEmpty ||
                                  p.mediaType == 'text')
                              .toList();

                          if (isLoading && myPosts.isEmpty) {
                            return const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          if (myPosts.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    IOSIcons.gridOff,
                                    size: 40,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No posts yet',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Share your first moment to see it here.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          switch (_selectedTab) {
                            case _ProfileTabType.grid:
                              // Instagram-style grid: show media posts only.
                              if (mediaPosts.isEmpty) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      IOSIcons.photoLibraryOutlined,
                                      size: 40,
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No photos or videos yet',
                                      style: theme.textTheme.titleSmall,
                                    ),
                                  ],
                                );
                              }

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 2,
                                  mainAxisSpacing: 2,
                                ),
                                itemCount: mediaPosts.length,
                                itemBuilder: (context, index) {
                                  final p = mediaPosts[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PostViewerScreen(
                                            posts: mediaPosts,
                                            initialIndex: index,
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          SafeNetworkImage(
                                            url: p.mediaUrl,
                                            fit: BoxFit.cover,
                                          ),
                                          if (p.mediaType == 'video')
                                            const Positioned(
                                              bottom: 4,
                                              right: 4,
                                              child: Icon(
                                                IOSIcons.playCircleFill,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          if (isOwnProfile)
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: PopupMenuButton<String>(
                                                padding: EdgeInsets.zero,
                                                iconSize: 18,
                                                icon: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withOpacity(0.35),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    IOSIcons.more,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                                onSelected: (value) async {
                                                  try {
                                                    if (value == 'archive') {
                                                      await PostService.instance
                                                          .archivePost(postId: p.id);
                                                    }
                                                    if (value == 'delete') {
                                                      await PostService.instance
                                                          .deletePost(postId: p.id);
                                                    }
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            value == 'archive'
                                                                ? 'Post archived'
                                                                : 'Post deleted',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  } catch (_) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Action failed'),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                itemBuilder: (_) => const [
                                                  PopupMenuItem(
                                                    value: 'archive',
                                                    child: Text('Archive'),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );

                            case _ProfileTabType.list:
                              // Show text posts as a list.
                              if (textPosts.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        IOSIcons.list,
                                        size: 40,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No text posts',
                                        style: theme.textTheme.titleSmall,
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return ListView.separated(
                                padding: const EdgeInsets.only(bottom: 24),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: textPosts.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 0),
                                itemBuilder: (context, index) {
                                  final p = textPosts[index];
                                  return _ProfileTweetCard(
                                    postId: p.id,
                                    onOpen: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PostViewerScreen(
                                            posts: textPosts,
                                            initialIndex: index,
                                          ),
                                        ),
                                      );
                                    },
                                    isOwner: isOwnProfile,
                                    username: user.username,
                                    timeAgo: _formatTimeAgo(p.createdAt),
                                    text: p.text,
                                    likeCount: p.likeCount,
                                    commentCount: p.commentCount,
                                    shareCount: p.shareCount,
                                  );
                                },
                              );

                            case _ProfileTabType.reels:
                              return StreamBuilder<List<Reel>>(
                                stream: ReelService.instance.watchReels(),
                                builder: (context, snap) {
                                  final reelsLoading = snap.connectionState ==
                                      ConnectionState.waiting;
                                  final allReels = snap.data ?? const <Reel>[];
                                  final myReels = allReels
                                      .where((r) => r.authorId == user.id)
                                      .toList();

                                  if (reelsLoading && allReels.isEmpty) {
                                    return const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }

                                  if (myReels.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 32),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            IOSIcons.film,
                                            size: 40,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No reels yet',
                                            style: theme.textTheme.titleSmall,
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return GridView.builder(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 2,
                                      mainAxisSpacing: 2,
                                    ),
                                    itemCount: myReels.length,
                                    itemBuilder: (context, index) {
                                      final r = myReels[index];
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => ReelsScreen(
                                                initialReelId: r.id,
                                              ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              if (r.mediaType == 'image')
                                                SafeNetworkImage(
                                                  url: r.mediaUrl,
                                                  fit: BoxFit.cover,
                                                )
                                              else
                                                Container(
                                                  color: theme.colorScheme
                                                      .surfaceContainer,
                                                  child: const Center(
                                                    child: Icon(
                                                      IOSIcons.playCircle,
                                                      size: 24,
                                                    ),
                                                  ),
                                                ),
                                              const Positioned(
                                                bottom: 4,
                                                right: 4,
                                                child: Icon(
                                                  IOSIcons.playCircleFill,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                              if (isOwnProfile)
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: PopupMenuButton<String>(
                                                    padding: EdgeInsets.zero,
                                                    iconSize: 18,
                                                    icon: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.35),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        IOSIcons.more,
                                                        color: Colors.white,
                                                        size: 14,
                                                      ),
                                                    ),
                                                    onSelected: (value) async {
                                                      try {
                                                        if (value == 'edit') {
                                                          final controller =
                                                              TextEditingController(
                                                                  text: r.caption);
                                                          final ok =
                                                              await showDialog<bool>(
                                                            context: context,
                                                            builder: (ctx) {
                                                              return AlertDialog(
                                                                title: const Text(
                                                                    'Edit reel'),
                                                                content: TextField(
                                                                  controller:
                                                                      controller,
                                                                  maxLines: 4,
                                                                  decoration:
                                                                      const InputDecoration(
                                                                    border:
                                                                        OutlineInputBorder(),
                                                                  ),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.of(ctx)
                                                                            .pop(false),
                                                                    child: const Text(
                                                                        'Cancel'),
                                                                  ),
                                                                  FilledButton(
                                                                    onPressed: () =>
                                                                        Navigator.of(ctx)
                                                                            .pop(true),
                                                                    child: const Text(
                                                                        'Save'),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                          if (ok == true) {
                                                            await ReelService
                                                                .instance
                                                                .updateReel(
                                                              reelId: r.id,
                                                              caption:
                                                                  controller.text,
                                                            );
                                                          }
                                                          controller.dispose();
                                                        }
                                                        if (value == 'archive') {
                                                          await ReelService.instance
                                                              .archiveReel(
                                                                  reelId: r.id);
                                                        }
                                                        if (value == 'delete') {
                                                          await ReelService.instance
                                                              .deleteReel(
                                                                  reelId: r.id);
                                                        }
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                value == 'archive'
                                                                    ? 'Reel archived'
                                                                    : value == 'delete'
                                                                        ? 'Reel deleted'
                                                                        : 'Reel updated',
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      } catch (_) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'Action failed'),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    itemBuilder: (_) => const [
                                                      PopupMenuItem(
                                                        value: 'edit',
                                                        child: Text('Edit'),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'archive',
                                                        child: Text('Archive'),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'delete',
                                                        child: Text('Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );

                            case _ProfileTabType.tagged:
                              // For now, reuse the existing fallback.
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.grid_off,
                                    size: 40,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Nothing here yet',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ],
                              );
                          }
                        },
                      ),
                    ),
                  ),
                  ),
                ],
              ),
              // Settings button (must be AFTER CustomScrollView to render on top)
              if (isOwnProfile)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(IOSIcons.settings, color: Colors.white),
                      tooltip: 'Settings',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  void _showFollowListSheet(
    BuildContext context, {
    required String title,
    required Stream<List<AppUser>> usersStream,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<AppUser>>(
                    stream: usersStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final users = snapshot.data!;
                      if (users.isEmpty) {
                        return const Center(child: Text('No users'));
                      }
                      return ListView.builder(
                        controller: controller,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              child: ClipOval(
                                child: (user.photoUrl != null &&
                                        user.photoUrl!.trim().isNotEmpty)
                                    ? SafeNetworkImage(
                                        url: user.photoUrl,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      )
                                    : Center(
                                        child: Text(
                                          user.username.isNotEmpty
                                              ? user.username[0].toUpperCase()
                                              : 'U',
                                        ),
                                      ),
                              ),
                            ),
                            title: Text(user.username),
                            subtitle: user.displayName != null ? Text(user.displayName!) : null,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<AppUser>> _fetchUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Firestore does not support whereIn with > 10; we support up to 30.
    final limited = ids.length > 30 ? ids.sublist(0, 30) : ids;
    final joined = limited.join(',');
    final rows = await AuthService.instance.api.getListOfMaps(
      '/api/users?ids=$joined',
    );
    return rows.map(AppUser.fromJson).toList();
  }

}


class _ProfileBackgroundMedia extends StatefulWidget {
  final String url;
  final double height;
  final bool isVideo;

  const _ProfileBackgroundMedia({
    required this.url,
    required this.height,
    required this.isVideo,
  });

  @override
  State<_ProfileBackgroundMedia> createState() =>
      _ProfileBackgroundMediaState();
}

class _ProfileBackgroundMediaState extends State<_ProfileBackgroundMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _controller = c;
      c.setLooping(true);
      c.setVolume(0);
      c.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        c.play();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ProfileBackgroundMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url == widget.url && oldWidget.isVideo == widget.isVideo) {
      return;
    }

    _controller?.dispose();
    _controller = null;

    if (widget.isVideo) {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _controller = c;
      c.setLooping(true);
      c.setVolume(0);
      c.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        c.play();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVideo) {
      return SafeNetworkImage(
        url: widget.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: widget.height,
      );
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return Container(color: Colors.black12);
    }

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}

class _HighlightsRow extends StatelessWidget {
  final String ownerId;
  final bool isOwnProfile;
  final Color accent;

  const _HighlightsRow({
    required this.ownerId,
    required this.isOwnProfile,
    required this.accent,
  });

  Future<void> _createHighlight(BuildContext context) async {
    final controller = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('New highlight'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Title',
              ),
              maxLength: 80,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Create'),
              ),
            ],
          );
        },
      );

      if (ok != true) return;
      final title = controller.text.trim();
      if (title.isEmpty) return;
      await StoryHighlightService.instance.createHighlight(title: title);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Highlight created.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<StoryHighlight>>(
      stream: StoryHighlightService.instance.watchUserHighlights(userId: ownerId),
      builder: (context, snapshot) {
        final highlights = snapshot.data ?? const <StoryHighlight>[];

        if (!isOwnProfile && highlights.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Highlights',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (isOwnProfile)
                  TextButton.icon(
                    onPressed: () => _createHighlight(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
                  ),
              ],
            ),
            SizedBox(
              height: 98,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final h = highlights[index];
                  final coverUrl = h.coverMediaUrl;

                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HighlightViewerScreen(highlight: h),
                        ),
                      );
                    },
                    onLongPress: !isOwnProfile
                        ? null
                        : () async {
                            final changed = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => HighlightEditScreen(highlight: h),
                              ),
                            );
                            if (changed == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Highlight updated.')),
                              );
                            }
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 78,
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent.withOpacity(0.75),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: (coverUrl != null && coverUrl.trim().isNotEmpty)
                                  ? SafeNetworkImage(
                                      url: coverUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: accent.withOpacity(0.12),
                                      alignment: Alignment.center,
                                      child: Text(
                                        h.title.trim().isNotEmpty
                                            ? h.title.trim()[0].toUpperCase()
                                            : 'H',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            h.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: highlights.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ProfileStat({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: content,
        ),
      ),
    );
  }
}

class _FollowersStat extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onTap;

  const _FollowersStat({required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: FollowService.instance.watchFollowers(uid: user.id),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return _ProfileStat(
          label: 'Followers',
          value: '$count',
          onTap: onTap,
        );
      },
    );
  }
}

class _FollowingStat extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onTap;

  const _FollowingStat({required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: FollowService.instance.watchFollowing(uid: user.id),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return _ProfileStat(
          label: 'Following',
          value: '$count',
          onTap: onTap,
        );
      },
    );
  }
}

enum _ProfileTabType { grid, list, reels, tagged }

class _ProfileTabRow extends StatelessWidget {
  final _ProfileTabType selected;
  final ValueChanged<_ProfileTabType> onSelected;

  const _ProfileTabRow({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segmented = SegmentedButton<_ProfileTabType>(
      segments: <ButtonSegment<_ProfileTabType>>[
        const ButtonSegment(
          value: _ProfileTabType.grid,
          icon: Icon(IOSIcons.grid),
          label: Text('Grid'),
        ),
        const ButtonSegment(
          value: _ProfileTabType.list,
          icon: Icon(IOSIcons.list),
          label: Text('List'),
        ),
        const ButtonSegment(
          value: _ProfileTabType.reels,
          icon: Icon(IOSIcons.film),
          label: Text('Reels'),
        ),
        const ButtonSegment(
          value: _ProfileTabType.tagged,
          icon: Icon(IOSIcons.tag),
          label: Text('Tagged'),
        ),
      ],
      selected: <_ProfileTabType>{selected},
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        textStyle: WidgetStatePropertyAll(
          theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      onSelectionChanged: (selection) {
        if (selection.isEmpty) return;
        onSelected(selection.first);
      },
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: segmented,
    );
  }
}

class _ProfileTweetCard extends StatelessWidget {
  final String postId;
  final VoidCallback? onOpen;
  final bool isOwner;
  final String username;
  final String timeAgo;
  final String text;
  final int likeCount;
  final int commentCount;
  final int shareCount;

  const _ProfileTweetCard({
    required this.postId,
    this.onOpen,
    required this.isOwner,
    required this.username,
    required this.timeAgo,
    required this.text,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
  });

  Future<void> _edit(BuildContext context) async {
    final controller = TextEditingController(text: text);
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Edit post'),
            content: TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
      if (ok != true) return;
      await PostService.instance.updatePost(
        postId: postId,
        text: controller.text,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated')),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _archive(BuildContext context) async {
    await PostService.instance.archivePost(postId: postId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post archived')),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete post?'),
          content: const Text('This will remove the post from your feed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    await PostService.instance.deletePost(postId: postId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  enabled: isOwner,
                  icon: const Icon(IOSIcons.more),
                  onSelected: (value) async {
                    if (!isOwner) return;
                    try {
                      if (value == 'edit') await _edit(context);
                      if (value == 'archive') await _archive(context);
                      if (value == 'delete') await _delete(context);
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Action failed')),
                      );
                    }
                  },
                  itemBuilder: (context) {
                    if (!isOwner) return const <PopupMenuEntry<String>>[];
                    return const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Text('Archive'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ProfileTweetStat(
                  icon: IOSIcons.heart,
                  count: likeCount,
                  onTap: () {},
                ),
                const SizedBox(width: 24),
                _ProfileTweetStat(
                  icon: IOSIcons.chatBubbleOutline,
                  count: commentCount,
                  onTap: () {},
                ),
                const SizedBox(width: 24),
                _ProfileTweetStat(
                  icon: IOSIcons.share,
                  count: shareCount,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTweetStat extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  const _ProfileTweetStat({
    required this.icon,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
