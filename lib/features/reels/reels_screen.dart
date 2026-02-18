import 'package:flutter/material.dart';

import '../../models/app_notification.dart';
import '../../models/app_user.dart';
import '../../models/comment.dart';
import '../../models/reel.dart';
import '../../services/block_service.dart';
import '../../services/comment_service.dart';
import '../../services/notification_service.dart';
import '../../services/reel_service.dart';
import '../../services/auth_service.dart';
import '../../theme/ios_icons.dart';
import '../chat/gif_picker_sheet.dart';
import '../chat/video_player_screen.dart';

class ReelsScreen extends StatelessWidget {
  final String? initialReelId;

  const ReelsScreen({
    super.key,
    this.initialReelId,
  });

  int _initialIndexFor(List<Reel> reels) {
    final id = initialReelId;
    if (id == null || id.isEmpty) return 0;
    final idx = reels.indexWhere((r) => r.id == id);
    return idx >= 0 ? idx : 0;
  }

  Future<List<Reel>> _filterReelsForBlocks({
    required List<Reel> reels,
    required String currentUserId,
  }) async {
    if (reels.isEmpty) return const <Reel>[];

    // Users I have blocked.
    final blockedByMe =
        await BlockService.instance.getBlockedOnce(uid: currentUserId);

    final result = <Reel>[];

    for (final reel in reels) {
      final authorId = reel.authorId;

      // Skip my own blocking list first.
      if (blockedByMe.contains(authorId)) {
        continue;
      }

      // Skip if the author has blocked me.
      final blockedMe = await BlockService.instance.isBlocked(
        fromUserId: authorId,
        toUserId: currentUserId,
      );
      if (blockedMe) continue;

      result.add(reel);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<List<Reel>>(
        stream: ReelService.instance.watchReels(),
        builder: (context, snapshot) {
          final allReels = snapshot.data ?? const <Reel>[];

          final me = AuthService.instance.currentUser;
          if (me == null) {
            // Logged out: show everything.
            if (allReels.isEmpty) {
              return const Center(
                child: Text(
                  'No reels yet',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final initialIndex = _initialIndexFor(allReels);
            return PageView.builder(
              controller: PageController(initialPage: initialIndex),
              scrollDirection: Axis.vertical,
              itemCount: allReels.length,
              itemBuilder: (context, index) {
                final reel = allReels[index];
                return _ReelPage(reel: reel);
              },
            );
          }

          return FutureBuilder<List<Reel>>(
            future: _filterReelsForBlocks(
              reels: allReels,
              currentUserId: me.id,
            ),
            builder: (context, filteredSnap) {
              if (filteredSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final reels = filteredSnap.data ?? const <Reel>[];

              if (reels.isEmpty) {
                return const Center(
                  child: Text(
                    'No reels yet',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final initialIndex = _initialIndexFor(reels);
              return PageView.builder(
                controller: PageController(initialPage: initialIndex),
                scrollDirection: Axis.vertical,
                itemCount: reels.length,
                itemBuilder: (context, index) {
                  final reel = reels[index];
                  return _ReelPage(reel: reel);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ReelCommentsSheet extends StatefulWidget {
  final String reelId;
  final String reelAuthorId;

  const _ReelCommentsSheet({
    required this.reelId,
    required this.reelAuthorId,
  });

  @override
  State<_ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends State<_ReelCommentsSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final me = AuthService.instance.currentUser;
    if (me == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to comment.')),
      );
      return;
    }

    final text = _controller.text;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    try {
      await CommentService.instance.addReelComment(
        reelId: widget.reelId,
        authorId: me.id,
        authorUsername: me.email,
        text: trimmed,
      );

      await NotificationService.instance.createNotification(
        toUserId: widget.reelAuthorId,
        type: AppNotificationType.comment,
        fromUserId: me.id,
        fromUsername: me.email,
        postId: widget.reelId,
      );

      _controller.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send comment.')),
      );
    }
  }

  Future<void> _sendGif(String gifUrl) async {
    final me = AuthService.instance.currentUser;
    if (me == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to comment.')),
      );
      return;
    }

    try {
      await CommentService.instance.addReelGifComment(
        reelId: widget.reelId,
        authorId: me.id,
        authorUsername: me.email,
        gifUrl: gifUrl,
      );

      await NotificationService.instance.createNotification(
        toUserId: widget.reelAuthorId,
        type: AppNotificationType.comment,
        fromUserId: me.id,
        fromUsername: me.email,
        postId: widget.reelId,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send comment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Text(
                      'Comments',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Comment>>(
                      stream: CommentService.instance.watchReelComments(
                        reelId: widget.reelId,
                      ),
                      builder: (context, snapshot) {
                        final comments = snapshot.data ?? [];

                        if (comments.isEmpty) {
                          return Center(
                            child: Text(
                              'No comments yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: onSurface.withOpacity(0.6),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          itemBuilder: (context, index) {
                            final c = comments[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<AppUser>(
                                  future: AuthService.instance.api.getJson(
                                    '/api/users/${c.authorId}',
                                    (json) => AppUser.fromJson(json),
                                  ),
                                  builder: (context, snap) {
                                    final photoUrl = snap.data?.photoUrl;
                                    return CircleAvatar(
                                      radius: 16,
                                      backgroundColor: theme
                                          .colorScheme.primary
                                          .withOpacity(0.12),
                                      backgroundImage: (photoUrl != null &&
                                              photoUrl.isNotEmpty)
                                          ? NetworkImage(photoUrl)
                                          : null,
                                      child: (photoUrl == null ||
                                              photoUrl.isEmpty)
                                          ? Text(
                                              c.authorUsername.isNotEmpty
                                                  ? c.authorUsername
                                                      .substring(0, 1)
                                                      .toUpperCase()
                                                  : 'U',
                                              style: TextStyle(
                                                color: theme
                                                    .colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            )
                                          : null,
                                    );
                                  },
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.authorUsername,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (c.type == CommentType.text)
                                        Text(
                                          c.text,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            height: 1.25,
                                          ),
                                        )
                                      else if (c.type == CommentType.gif &&
                                          c.mediaUrl != null &&
                                          c.mediaUrl!.isNotEmpty)
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            c.mediaUrl!,
                                            height: 160,
                                            width: 160,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemCount: comments.length,
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(IOSIcons.gif),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (ctx) {
                                return GifPickerSheet(
                                  onSelected: (gif) {
                                    Navigator.of(ctx).pop();
                                    _sendGif(gif.originalUrl);
                                  },
                                );
                              },
                            );
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(999),
                                ),
                              ),
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(IOSIcons.send),
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          )),
    );
  }
}

String _formatCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toString();
}

String _formatTimeAgo(DateTime createdAt) {
  final now = DateTime.now();
  final diff = now.difference(createdAt);

  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';

  final weeks = (diff.inDays / 7).floor();
  if (weeks < 4) return '${weeks}w';

  final months = (diff.inDays / 30).floor();
  if (months < 12) return '${months}mo';

  final years = (diff.inDays / 365).floor();
  return '${years}y';
}

class _ReelPage extends StatelessWidget {
  final Reel reel;

  const _ReelPage({required this.reel});

  Future<void> _editCaption(BuildContext context) async {
    final controller = TextEditingController(text: reel.caption);
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Edit reel'),
            content: TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
      if (ok != true) return;
      await ReelService.instance.updateReel(
        reelId: reel.id,
        caption: controller.text,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reel updated')),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _archive(BuildContext context) async {
    await ReelService.instance.archiveReel(reelId: reel.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reel archived')),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete reel?'),
          content: const Text('This will remove the reel from your feed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    await ReelService.instance.deleteReel(reelId: reel.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reel deleted')),
    );
  }

  Future<void> _toggleLike() async {
    final me = AuthService.instance.currentUser;
    if (me == null) return;

    await ReelService.instance.toggleLike(
      reelId: reel.id,
      userId: me.id,
    );
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return _ReelCommentsSheet(reelId: reel.id, reelAuthorId: reel.authorId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentUserId = AuthService.instance.currentUser?.id;
    final isOwner = currentUserId != null && currentUserId == reel.authorId;

    return GestureDetector(
      onDoubleTap: _toggleLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media background (image/video/text).
          if (reel.mediaType == 'image' &&
              reel.mediaUrl != null &&
              reel.mediaUrl!.isNotEmpty)
            Image.network(
              reel.mediaUrl!,
              fit: BoxFit.cover,
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF111827),
                    Color(0xFF020617),
                  ],
                ),
              ),
            ),

          // If this is a video reel, show a play overlay that opens the player.
          if (reel.mediaType == 'video' &&
              reel.mediaUrl != null &&
              reel.mediaUrl!.isNotEmpty)
            Center(
              child: IconButton(
                iconSize: 72,
                color: Colors.white,
                icon: const Icon(IOSIcons.playCircle),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(url: reel.mediaUrl!),
                    ),
                  );
                },
              ),
            ),
          // Dark overlay for text legibility.
          Container(
            color: Colors.black.withOpacity(0.25),
          ),
          // Top app bar style overlay.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Reels',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Prototype',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon:
                        const Icon(IOSIcons.camera, color: Colors.white),
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      icon: const Icon(IOSIcons.more, color: Colors.white),
                      onSelected: (value) async {
                        try {
                          if (value == 'edit') await _editCaption(context);
                          if (value == 'archive') await _archive(context);
                          if (value == 'delete') await _delete(context);
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Action failed')),
                          );
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
                ],
              ),
            ),
          ),
        // Right side actions.
        Positioned(
          right: 12,
          bottom: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(builder: (context) {
                final currentUserId =
                    AuthService.instance.currentUser?.id;
                final isLiked = currentUserId != null &&
                    reel.likedBy.contains(currentUserId);
                return _ReelActionButton(
                  icon: isLiked
                      ? IOSIcons.heartFill
                      : IOSIcons.heart,
                  label: _formatCount(reel.likeCount),
                  onTap: () async {
                    await _toggleLike();
                  },
                );
              }),
              const SizedBox(height: 18),
              _ReelActionButton(
                icon: IOSIcons.chatBubbleOutline,
                label: _formatCount(reel.commentCount),
                onTap: () {
                  _openComments(context);
                },
              ),
              const SizedBox(height: 18),
              _ReelActionButton(
                icon: IOSIcons.shareUp,
                label: _formatCount(reel.shareCount),
                onTap: () async {
                  final me = AuthService.instance.currentUser;
                  if (me == null) return;

                  await ReelService.instance.repost(
                    sourceReelId: reel.id,
                    newAuthorId: me.id,
                    newAuthorUsername: me.email,
                  );
                },
              ),
              const SizedBox(height: 26),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                child: Icon(IOSIcons.musicNote, color: Colors.white),
              ),
            ],
          ),
        ),
        // Bottom caption + author.
        Positioned(
          left: 16,
          right: 90,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    child: Icon(IOSIcons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '@${reel.authorUsername}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTimeAgo(reel.createdAt),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Follow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                reel.caption,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.25,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}

class _ReelActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ReelActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
