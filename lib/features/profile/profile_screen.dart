import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/app_user.dart';
import '../../models/post.dart';
import '../../models/reel.dart';
import '../../services/auth_service.dart';
import '../../services/follow_service.dart';
import '../../services/post_service.dart';
import '../../services/reel_service.dart';
import '../../theme/ios_icons.dart';
import '../post/post_viewer_screen.dart';
import '../reels/reels_screen.dart';
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
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickBackgroundImage(AppUser user) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    try {
      final bytes = await pickedFile.readAsBytes();
      final res = await AuthService.instance.api.uploadFile(
        path: '/api/uploads',
        bytes: bytes,
        filename: pickedFile.name,
      );
      final url = (res['url'] as String?) ?? '';
      if (url.isEmpty) throw Exception('Upload failed');

      await AuthService.instance.api.patchNoContent(
        '/api/users/me',
        body: {'backgroundImageUrl': url},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background photo updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<AppUser?>(
      future: _loadUser(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('User not found')),
          );
        }

        final me = AuthService.instance.currentUser;
        final isOwnProfile = widget.userId == null || (me != null && me.id == user.id);

        return Scaffold(
          body: Stack(
            children: [
              // Background image with camera button
              if (user.backgroundImageUrl != null && user.backgroundImageUrl!.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 200,
                  child: Image.network(
                    user.backgroundImageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
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
                        theme.colorScheme.primary.withOpacity(0.12),
                        theme.scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 520,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.none,
                      background: Container(
                        color: theme.scaffoldBackgroundColor,
                        child: Column(
                          children: [
                            const SizedBox(height: 160),
                            // Profile photo overlapping the cover
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
                                  child: CircleAvatar(
                                    radius: 54,
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                        ? NetworkImage(user.photoUrl!)
                                        : null,
                                    child: user.photoUrl == null || user.photoUrl!.isEmpty
                                        ? Text(
                                            user.username.isNotEmpty
                                                ? user.username[0].toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              color: theme.colorScheme.onPrimaryContainer,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 36,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                // Avatar upload button (bottom right corner)
                                if (isOwnProfile)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _pickAvatarImage(user),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8D5CF6),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.camera,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Name and handle
                            Text(
                              user.username,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${user.username.toLowerCase().replaceAll(' ', '_')}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Stats row
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Posts count
                                  StreamBuilder<List<Post>>(
                                    stream: PostService.instance.watchRecentPosts(),
                                    builder: (context, snapshot) {
                                      final count = snapshot.data?.where((p) => p.authorId == user.id).length ?? 0;
                                      return _ProfileStat(label: 'Post', value: count.toString());
                                    },
                                  ),
                                  Container(
                                    height: 24,
                                    width: 1,
                                    color: theme.dividerColor,
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                  ),
                                  _FollowersStat(
                                    user: user,
                                    onTap: () {
                                      _showFollowListSheet(
                                        context,
                                        title: 'Followers',
                                        usersStream: _usersStreamFromIds(
                                          FollowService.instance.watchFollowers(uid: user.id),
                                        ),
                                      );
                                    },
                                  ),
                                  Container(
                                    height: 24,
                                    width: 1,
                                    color: theme.dividerColor,
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                  ),
                                  _FollowingStat(
                                    user: user,
                                    onTap: () {
                                      _showFollowListSheet(
                                        context,
                                        title: 'Following',
                                        usersStream: _usersStreamFromIds(
                                          FollowService.instance.watchFollowing(uid: user.id),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Action buttons
                            if (!isOwnProfile)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          // Navigate to chat
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          side: BorderSide(color: theme.colorScheme.outline),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                        ),
                                        child: const Text('Message'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: StreamBuilder<bool>(
                                        stream: FollowService.instance.watchIsFollowing(
                                          fromUserId: (me?.id ?? ''),
                                          toUserId: user.id,
                                        ),
                                        builder: (context, snapshot) {
                                          final isFollowing = snapshot.data ?? false;
                                          return ElevatedButton(
                                            onPressed: () async {
                                              if (me == null) return;
                                              try {
                                                if (isFollowing) {
                                                  await FollowService.instance.unfollow(
                                                    fromUserId: me.id,
                                                    toUserId: user.id,
                                                  );
                                                } else {
                                                  await FollowService.instance.follow(
                                                    fromUserId: me.id,
                                                    toUserId: user.id,
                                                  );
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Error: $e')),
                                                  );
                                                }
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFD4943A),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(24),
                                              ),
                                            ),
                                            child: Text(isFollowing ? 'Following' : 'Follow'),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isOwnProfile)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => EditProfileScreen(user: user),
                                        ),
                                      );
                                    },
                                    icon: const Icon(IOSIcons.editOutlined),
                                    label: const Text('Edit Profile'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: BorderSide(color: theme.colorScheme.outline),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
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
                      child: StreamBuilder<List<Post>>(
                        stream: PostService.instance.watchRecentPosts(),
                        builder: (context, snapshot) {
                          final all = snapshot.data ?? const <Post>[];
                          final myPosts = all
                              .where((p) => p.authorId == user.id)
                              .toList();
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

                          if (myPosts.isEmpty) {
                            return Column(
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
                                          p.mediaUrl != null
                                              ? Image.network(
                                                  p.mediaUrl!,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: theme.colorScheme.surfaceContainer,
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
                                return const Center(child: Text('No text posts'));
                              }
                              return ListView.separated(
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
                                  final allReels = snap.data ?? const <Reel>[];
                                  final myReels = allReels
                                      .where((r) => r.authorId == user.id)
                                      .toList();

                                  if (myReels.isEmpty) {
                                    return Column(
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
                                    );
                                  }

                                  return GridView.builder(
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
                                              if (r.mediaType == 'image' &&
                                                  r.mediaUrl != null &&
                                                  r.mediaUrl!.isNotEmpty)
                                                Image.network(
                                                  r.mediaUrl!,
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
                ],
              ),
              // Camera button overlay (must be AFTER CustomScrollView to render on top)
              if (isOwnProfile)
                Positioned(
                  top: 160,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _pickBackgroundImage(user),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8D5CF6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.camera,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
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
                              backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                  ? NetworkImage(user.photoUrl!)
                                  : null,
                              child: user.photoUrl == null || user.photoUrl!.isEmpty
                                  ? Text(user.username.isNotEmpty
                                      ? user.username[0].toUpperCase()
                                      : 'U')
                                  : null,
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
    return Future(() async {
      final limited = ids.length > 30 ? ids.sublist(0, 30) : ids;
      final joined = limited.join(',');
      final rows = await AuthService.instance.api
          .getListOfMaps('/api/users?ids=$joined');
      return rows.map(AppUser.fromJson).toList();
    });
  }

  Future<void> _pickAvatarImage(AppUser user) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      final bytes = await pickedFile.readAsBytes();
      final res = await AuthService.instance.api.uploadFile(
        path: '/api/uploads',
        bytes: bytes,
        filename: pickedFile.name,
      );
      final downloadUrl = (res['url'] as String?) ?? '';
      if (downloadUrl.isEmpty) throw Exception('Upload failed');

      await AuthService.instance.api.patchNoContent(
        '/api/users/me',
        body: {'photoUrl': downloadUrl},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload avatar: $e')),
        );
      }
    }
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
  }
}

class _FollowersStat extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onTap;

  const _FollowersStat({required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<String>>(
      stream: FollowService.instance.watchFollowers(uid: user.id),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              Text(
                '$count',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Followers',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
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
    final theme = Theme.of(context);
    return StreamBuilder<List<String>>(
      stream: FollowService.instance.watchFollowing(uid: user.id),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              Text(
                '$count',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Following',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
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
    return Row(
      children: [
        Expanded(
          child: _ProfileTabButton(
            icon: IOSIcons.grid,
            label: 'Grid',
            isSelected: selected == _ProfileTabType.grid,
            onTap: () => onSelected(_ProfileTabType.grid),
          ),
        ),
        Expanded(
          child: _ProfileTabButton(
            icon: IOSIcons.list,
            label: 'List',
            isSelected: selected == _ProfileTabType.list,
            onTap: () => onSelected(_ProfileTabType.list),
          ),
        ),
        Expanded(
          child: _ProfileTabButton(
            icon: IOSIcons.film,
            label: 'Reels',
            isSelected: selected == _ProfileTabType.reels,
            onTap: () => onSelected(_ProfileTabType.reels),
          ),
        ),
        Expanded(
          child: _ProfileTabButton(
            icon: IOSIcons.tag,
            label: 'Tagged',
            isSelected: selected == _ProfileTabType.tagged,
            onTap: () => onSelected(_ProfileTabType.tagged),
          ),
        ),
      ],
    );
  }
}

class _ProfileTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.6);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
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
