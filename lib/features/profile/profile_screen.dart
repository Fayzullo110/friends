import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/app_user.dart';
import '../../models/post.dart';
import '../../services/follow_service.dart';
import '../../services/post_service.dart';
import '../../theme/ios_icons.dart';
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

  Future<void> _pickBackgroundImage(AppUser user) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    try {
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('backgrounds')
          .child('${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({'backgroundImageUrl': downloadUrl});

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

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId ?? FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('User not found')),
          );
        }

        final user = AppUser.fromDoc(snap.data!);
        final isOwnProfile = widget.userId == null || widget.userId == FirebaseAuth.instance.currentUser?.uid;
        final currentUser = FirebaseAuth.instance.currentUser;

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
                                          fromUserId: currentUser?.uid ?? '',
                                          toUserId: user.id,
                                        ),
                                        builder: (context, snapshot) {
                                          final isFollowing = snapshot.data ?? false;
                                          return ElevatedButton(
                                            onPressed: () async {
                                              if (currentUser == null) return;
                                              try {
                                                if (isFollowing) {
                                                  await FollowService.instance.unfollow(
                                                    fromUserId: currentUser.uid,
                                                    toUserId: user.id,
                                                  );
                                                } else {
                                                  await FollowService.instance.follow(
                                                    fromUserId: currentUser.uid,
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
                                  return ClipRRect(
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
                                      ],
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

  Stream<List<AppUser>> _usersStreamFromIds(Stream<List<String>> idsStream) {
    return idsStream.asyncMap((ids) async {
      if (ids.isEmpty) return <AppUser>[];
      final limited = ids.length > 30 ? ids.sublist(0, 30) : ids;
      final docs = await Future.wait(
        limited.map(
          (uid) => FirebaseFirestore.instance.collection('users').doc(uid).get(),
        ),
      );
      return docs
          .where((d) => d.exists)
          .map((d) => AppUser.fromDoc(d))
          .toList();
    });
  }

  Future<void> _pickAvatarImage(AppUser user) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.id)
          .child('avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(File(pickedFile.path));
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({'photoUrl': downloadUrl});

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
  final String username;
  final String timeAgo;
  final String text;
  final int likeCount;
  final int commentCount;
  final int shareCount;

  const _ProfileTweetCard({
    required this.username,
    required this.timeAgo,
    required this.text,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
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
              IconButton(
                onPressed: () {},
                icon: const Icon(IOSIcons.more),
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
