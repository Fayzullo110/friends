import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/ios_icons.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../models/story.dart';
import '../../models/app_user.dart';
import '../../models/app_notification.dart';
import '../../services/comment_service.dart';
import '../../services/notification_service.dart';
import '../../services/post_service.dart';
import '../../services/story_service.dart';
import '../../services/auth_service.dart';
import '../../services/block_service.dart';
import '../chat/gif_picker_sheet.dart';
import '../notifications/notifications_screen.dart';
import '../friends/user_search_screen.dart';
import '../story/create_story_screen.dart';
import '../story/story_viewer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/Logo.png',
                height: 28,
                width: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Friends',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(IOSIcons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const UserSearchScreen(),
                ),
              );
            },
          ),
          Builder(
            builder: (context) {
              final me = AuthService.instance.currentUser;
              if (me == null) {
                return IconButton(
                  icon: const Icon(IOSIcons.bell),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                );
              }

              return StreamBuilder<List<AppNotification>>(
                stream: NotificationService.instance
                    .watchMyUnreadNotifications(uid: me.id),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const <AppNotification>[];
                  final count = items.length;

                  Widget icon = const Icon(IOSIcons.bell);
                  if (count > 0) {
                    final display = count > 9 ? '9+' : '$count';
                    icon = Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(IOSIcons.bell),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              display,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return IconButton(
                    icon: icon,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Post>>(
        stream: PostService.instance.watchRecentPosts(),
        builder: (context, snapshot) {
          final rawPosts = snapshot.data ?? [];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          final me = AuthService.instance.currentUser;

          Widget buildFeed(List<Post> posts) {
            return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withOpacity(0.98),
                  theme.colorScheme.surfaceVariant.withOpacity(0.96),
                ],
              ),
            ),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: _StoriesRow(),
                ),
              if (isLoading && posts.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(height: 12),
                          Text('Loading moments…'),
                        ],
                      ),
                    ),
                  ),
                )
                else if (posts.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No moments yet. Be the first to share a thought!',
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = posts[index];
                        final isTextOnly =
                            post.mediaUrl == null || post.mediaUrl!.isEmpty;
                        final item = _PostItemData(
                          id: post.id,
                          authorId: post.authorId,
                          username: post.authorUsername,
                          authorPhotoUrl: post.authorPhotoUrl,
                          timeAgo: _formatTimeAgo(post.createdAt),
                          isTextOnly: isTextOnly,
                          text: post.text,
                          imageUrl: isTextOnly ? null : post.mediaUrl,
                          likeCount: post.likeCount,
                          likedBy: post.likedBy,
                          commentCount: post.commentCount,
                          shareCount: post.shareCount,
                          isVideo: post.mediaType == 'video',
                        );
                        return _PostCard(post: item);
                      },
                      childCount: posts.length,
                    ),
                  ),
              ],
            ),
          );
          }

          // If not logged in, show all posts.
          if (me == null) {
            return buildFeed(rawPosts);
          }

          // If logged in, hide posts from users I blocked AND users who have
          // blocked me (best-effort using Firestore reads per author).
          return FutureBuilder<List<Post>>(
            future: () async {
              final myBlockedIds = await BlockService.instance
                  .getBlockedOnce(uid: me.id);

              // First filter out authors I have blocked.
              final byOthers = rawPosts
                  .where((p) => !myBlockedIds.contains(p.authorId))
                  .toList();

              // Then check which authors have blocked me.
              final authorIds = byOthers.map((p) => p.authorId).toSet().toList();
              final futures = authorIds.map((authorId) async {
                final blockedMe = await BlockService.instance.isBlocked(
                  fromUserId: authorId,
                  toUserId: me.id,
                );
                return MapEntry(authorId, blockedMe);
              }).toList();

              final results = await Future.wait(futures);
              final blockedMeAuthors = results
                  .where((e) => e.value)
                  .map((e) => e.key)
                  .toSet();

              return byOthers
                  .where((p) => !blockedMeAuthors.contains(p.authorId))
                  .toList();
            }(),
            builder: (context, filteredSnap) {
              final filteredPosts = filteredSnap.data ?? rawPosts;
              return buildFeed(filteredPosts);
            },
          );
        },
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final String postId;
  final String postAuthorId;

  const _CommentsSheet({
    required this.postId,
    required this.postAuthorId,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _controller = TextEditingController();
  Comment? _replyTo;
  String? _pinnedCommentId;

  @override
  void initState() {
    super.initState();
    _pinnedCommentId = null;
  }

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
      await CommentService.instance.addComment(
        postId: widget.postId,
        authorId: me.id,
        authorUsername: me.email,
        text: trimmed,
        parentCommentId: _replyTo?.id,
      );

      await NotificationService.instance.createNotification(
        toUserId: widget.postAuthorId,
        type: AppNotificationType.comment,
        fromUserId: me.id,
        fromUsername: me.email,
        postId: widget.postId,
      );

      _controller.clear();
      setState(() {
        _replyTo = null;
      });
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
      await CommentService.instance.addGifComment(
        postId: widget.postId,
        authorId: me.id,
        authorUsername: me.email,
        gifUrl: gifUrl,
        parentCommentId: _replyTo?.id,
      );

      await NotificationService.instance.createNotification(
        toUserId: widget.postAuthorId,
        type: AppNotificationType.comment,
        fromUserId: me.id,
        fromUsername: me.email,
        postId: widget.postId,
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
                    stream: CommentService.instance.watchComments(
                      postId: widget.postId,
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

                      final pinnedId = _pinnedCommentId;
                      final List<Comment> ordered;
                      if (pinnedId == null) {
                        ordered = comments;
                      } else {
                        final pinned =
                            comments.where((c) => c.id == pinnedId).toList();
                        final rest =
                            comments.where((c) => c.id != pinnedId).toList();
                        ordered = [...pinned, ...rest];
                      }

                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        itemBuilder: (context, index) {
                          final c = ordered[index];
                          final currentUserId =
                              AuthService.instance.currentUser?.id;
                          final isLiked = currentUserId != null &&
                              c.likedBy.contains(currentUserId);
                          final isDisliked = currentUserId != null &&
                              c.dislikedBy.contains(currentUserId);
                          final isReply = c.parentCommentId != null;
                          final isPinned = c.id == _pinnedCommentId;
                          return Padding(
                            padding: EdgeInsets.only(left: isReply ? 40 : 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      theme.colorScheme.primary.withOpacity(0.12),
                                  foregroundImage: (c.authorPhotoUrl != null &&
                                          c.authorPhotoUrl!.isNotEmpty)
                                      ? NetworkImage(c.authorPhotoUrl!)
                                      : null,
                                  child: Text(
                                    c.authorUsername.isNotEmpty
                                        ? c.authorUsername
                                            .substring(0, 1)
                                            .toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: c.mediaUrl!,
                                          height: 160,
                                          width: 160,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (isPinned)
                                          Container(
                                            margin: const EdgeInsets.only(
                                                right: 8),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              color: theme.colorScheme.primary
                                                  .withOpacity(0.08),
                                            ),
                                            child: Text(
                                              'Pinned',
                                              style: theme
                                                  .textTheme.labelSmall
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          _formatTimeAgo(c.createdAt),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          onTap: currentUserId == null
                                              ? null
                                              : () {
                                                  CommentService.instance
                                                      .toggleLikeComment(
                                                    postId: widget.postId,
                                                    commentId: c.id,
                                                    userId: currentUserId,
                                                  );
                                                },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isLiked
                                                    ? IOSIcons.heartFill
                                                    : IOSIcons.heart,
                                                size: 16,
                                                color: isLiked
                                                    ? theme.colorScheme.error
                                                    : onSurface
                                                        .withOpacity(0.7),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                c.likeCount.toString(),
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: onSurface
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          onTap: currentUserId == null
                                              ? null
                                              : () {
                                                  CommentService.instance
                                                      .toggleDislikeComment(
                                                    postId: widget.postId,
                                                    commentId: c.id,
                                                    userId: currentUserId,
                                                  );
                                                },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isDisliked
                                                    ? IOSIcons.handThumbsdownFill
                                                    : IOSIcons.handThumbsdown,
                                                size: 16,
                                                color: isDisliked
                                                    ? theme
                                                        .colorScheme.primary
                                                    : onSurface
                                                        .withOpacity(0.7),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                c.dislikeCount.toString(),
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: onSurface
                                                      .withOpacity(0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _replyTo = c;
                                              _controller.text =
                                                  '@${c.authorUsername} ';
                                              _controller.selection =
                                                  TextSelection.fromPosition(
                                                TextPosition(
                                                    offset: _controller
                                                        .text.length),
                                              );
                                            });
                                          },
                                          child: const Text('Reply'),
                                        ),
                                        if (currentUserId ==
                                                widget.postAuthorId &&
                                            !isReply)
                                          TextButton(
                                            onPressed: () async {
                                              final unpin =
                                                  _pinnedCommentId == c.id;
                                              await PostService.instance
                                                  .setPinnedComment(
                                                postId: widget.postId,
                                                commentId:
                                                    unpin ? null : c.id,
                                              );
                                              if (!mounted) return;
                                              setState(() {
                                                _pinnedCommentId =
                                                    unpin ? null : c.id;
                                              });
                                            },
                                            child: Text(
                                              isPinned ? 'Unpin' : 'Pin',
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => Divider(
                          height: 16,
                          color: onSurface.withOpacity(0.08),
                        ),
                        itemCount: comments.length,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(IOSIcons.photo),
                        onPressed: () async {
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
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
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: 'Write a comment…',
                            filled: true,
                            fillColor:
                                theme.colorScheme.surfaceVariant.withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: _submit,
                        icon: const Icon(IOSIcons.send),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _formatTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

class _StoriesRow extends StatelessWidget {
  const _StoriesRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            AppLocalizations.of(context)!.circles,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 96,
          child: StreamBuilder<List<Story>>(
            stream: StoryService.instance.watchActiveStories(),
            builder: (context, snapshot) {
              final allStories = snapshot.data ?? const <Story>[];

              // If not logged in, just group all stories by author. Seen state
              // is not tracked when there is no authenticated user.
              final me = AuthService.instance.currentUser;
              if (me == null) {
                final Map<String, List<Story>> byUser = {};
                for (final s in allStories) {
                  byUser.putIfAbsent(s.authorId, () => []).add(s);
                }
                final userIds = byUser.keys.toList();

                return StreamBuilder<AppUser?>(
                  stream: AuthService.instance.userChanges,
                  builder: (context, meSnap) {
                    final me = meSnap.data;

                    return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemBuilder: (context, index) {
                      // First item is always current user shortcut.
                      if (index == 0) {
                        final List<Story> myStories =
                            me != null ? byUser[me.id] ?? const <Story>[] : const <Story>[];
                        final hasStories = myStories.isNotEmpty;
                        const allSeen = false;

                        return _StoryAvatar(
                          label: me?.username ?? 'You',
                          isCurrentUser: true,
                          hasStory: hasStories,
                          isSeen: allSeen,
                          photoUrl: me?.photoUrl,
                          onTap: () {
                            if (!context.mounted) return;
                            if (!hasStories) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CreateStoryScreen(),
                                ),
                              );
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StoryViewerScreen(
                                    stories: myStories,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      }

                      // Other users' stories.
                      final userId =
                          index - 1 < userIds.length ? userIds[index - 1] : '';
                      if (userId.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final List<Story> userStories =
                          byUser[userId] ?? const <Story>[];
                      if (userStories.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final firstStory = userStories.first;
                      final username = firstStory.authorUsername.isNotEmpty
                          ? firstStory.authorUsername
                          : 'friend';

                      const isSeen = false;

                      return _StoryAvatar(
                        label: username,
                        isCurrentUser: false,
                        hasStory: true,
                        isSeen: isSeen,
                        onTap: () {
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StoryViewerScreen(
                                stories: userStories,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    // 1 for "You" + number of users with stories.
                    itemCount: 1 + userIds.length,
                  );
                },
              );
              }

              // Logged in: hide stories from users I blocked AND users who
              // have blocked me, and compute seen state using my uid.
              return FutureBuilder<Map<String, List<Story>>>(
                future: () async {
                  final myBlockedIds = await BlockService.instance
                      .getBlockedOnce(uid: me.id);

                  // Authors for all stories except those I have blocked.
                  final stories = allStories
                      .where((s) => !myBlockedIds.contains(s.authorId))
                      .toList();
                  final authorIds =
                      stories.map((s) => s.authorId).toSet().toList();

                  final futures = authorIds.map((authorId) async {
                    final blockedMe = await BlockService.instance.isBlocked(
                      fromUserId: authorId,
                      toUserId: me.id,
                    );
                    return MapEntry(authorId, blockedMe);
                  }).toList();

                  final results = await Future.wait(futures);
                  final blockedMeAuthors = results
                      .where((e) => e.value)
                      .map((e) => e.key)
                      .toSet();

                  final visibleStories = stories
                      .where((s) => !blockedMeAuthors.contains(s.authorId))
                      .toList();

                  final Map<String, List<Story>> byUser = {};
                  for (final s in visibleStories) {
                    byUser.putIfAbsent(s.authorId, () => []).add(s);
                  }
                  return byUser;
                }(),
                builder: (context, filteredSnap) {
                  final byUser = filteredSnap.data ?? <String, List<Story>>{};
                  final userIds = byUser.keys
                      .where((id) => id != me.id)
                      .toList();

                  return StreamBuilder<AppUser?>(
                    stream: AuthService.instance.userChanges,
                    builder: (context, meSnap) {
                      final meProfile = meSnap.data;

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemBuilder: (context, index) {
                          // First item is always current user shortcut.
                          if (index == 0) {
                            final List<Story> myStoriesFromActive =
                                byUser[me.id] ?? const <Story>[];
                            return StreamBuilder<List<Story>>(
                              stream: StoryService.instance
                                  .watchUserStories(authorId: me.id),
                              initialData: myStoriesFromActive,
                              builder: (context, mySnap) {
                                final raw = mySnap.hasError
                                    ? myStoriesFromActive
                                    : (mySnap.data ?? const <Story>[]);

                                final streamStories = List<Story>.from(raw)
                                  ..sort(
                                    (a, b) => a.createdAt.compareTo(b.createdAt),
                                  );
                                final activeStories = List<Story>.from(myStoriesFromActive)
                                  ..sort(
                                    (a, b) => a.createdAt.compareTo(b.createdAt),
                                  );

                                // Merge both sources (best-effort) so multiple stories never disappear
                                // due to a late/empty stream snapshot.
                                final mergedById = <String, Story>{};
                                for (final s in activeStories) {
                                  mergedById[s.id] = s;
                                }
                                for (final s in streamStories) {
                                  mergedById[s.id] = s;
                                }

                                final effectiveStories = mergedById.values.toList()
                                  ..sort(
                                    (a, b) => a.createdAt.compareTo(b.createdAt),
                                  );

                                final hasStories = effectiveStories.isNotEmpty;
                                final allSeen = hasStories
                                    ? effectiveStories.every(
                                        (s) =>
                                            s.seenBy.contains(me.id),
                                      )
                                    : false;

                                return _StoryAvatar(
                                  label: meProfile?.username ?? 'You',
                                  isCurrentUser: true,
                                  hasStory: hasStories,
                                  isSeen: allSeen,
                                  photoUrl: meProfile?.photoUrl,
                                  onTap: () {
                                    if (!context.mounted) return;
                                    if (!hasStories) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CreateStoryScreen(),
                                        ),
                                      );
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => StoryViewerScreen(
                                            stories: List<Story>.from(effectiveStories),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  onLongPress: () {
                                    if (!context.mounted) return;
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CreateStoryScreen(),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          }

                          // Other users' stories.
                          final userId = index - 1 < userIds.length
                              ? userIds[index - 1]
                              : '';
                          if (userId.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final List<Story> userStories =
                              byUser[userId] ?? const <Story>[];
                          if (userStories.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final sortedStories = List<Story>.from(userStories)
                            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

                          final firstStory = sortedStories.first;
                          final username = firstStory.authorUsername.isNotEmpty
                              ? firstStory.authorUsername
                              : 'friend';

                          final isSeen = sortedStories.every(
                            (s) => s.seenBy.contains(me.id),
                          );

                          return _StoryAvatar(
                            label: username,
                            isCurrentUser: false,
                            hasStory: true,
                            isSeen: isSeen,
                            onTap: () {
                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StoryViewerScreen(
                                    stories: sortedStories,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        // 1 for "You" + number of users with stories.
                        itemCount: 1 + userIds.length,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String label;
  final bool isCurrentUser;
  final bool hasStory;
  final bool isSeen;
  final String? photoUrl;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _StoryAvatar({
    required this.label,
    this.isCurrentUser = false,
    this.hasStory = false,
    this.isSeen = false,
    this.photoUrl,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = isCurrentUser
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;
    final borderColor = hasStory
        ? (isSeen
            ? baseColor.withOpacity(0.4)
            : baseColor) // brighter ring when unseen
        : theme.colorScheme.outline.withOpacity(0.4);
    return SizedBox(
      height: 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.surfaceVariant,
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl!) : null,
                child: photoUrl == null
                    ? Icon(
                        isCurrentUser
                            ? Icons.add_circle_outline
                            : Icons.person,
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.8),
                      )
                    : null,
              ),
            ),
          ),
        const SizedBox(height: 2),
        SizedBox(
          width: 70,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
      ),
    );
  }
}

class _PostItemData {
  final String id;
  final String authorId;
  final String username;
  final String? authorPhotoUrl;
  final String timeAgo;
  final bool isTextOnly;
  final String text;
  final String? imageUrl;
  final int likeCount;
  final List<String> likedBy;
  final int commentCount;
  final int shareCount;
  final bool isVideo;

  _PostItemData({
    required this.id,
    required this.authorId,
    required this.username,
    this.authorPhotoUrl,
    required this.timeAgo,
    required this.isTextOnly,
    required this.text,
    this.imageUrl,
    required this.likeCount,
    required this.likedBy,
    required this.commentCount,
    required this.shareCount,
    this.isVideo = false,
  });
}

class _PostCard extends StatelessWidget {
  final _PostItemData post;

  const _PostCard({required this.post});

  Future<void> _editPost(BuildContext context) async {
    final controller = TextEditingController(text: post.text);
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
      await PostService.instance.updatePost(postId: post.id, text: controller.text);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated')),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _archivePost(BuildContext context) async {
    await PostService.instance.archivePost(postId: post.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post archived')),
    );
  }

  Future<void> _deletePost(BuildContext context) async {
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
    await PostService.instance.deletePost(postId: post.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post deleted')),
    );
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return _CommentsSheet(
          postId: post.id,
          postAuthorId: post.authorId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final currentUserId = AuthService.instance.currentUser?.id;
    final isLiked = currentUserId != null && post.likedBy.contains(currentUserId);
    final isOwner = currentUserId != null && currentUserId == post.authorId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.18),
              blurRadius: 18,
              spreadRadius: -4,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.12),
                      foregroundImage: (post.authorPhotoUrl != null &&
                              post.authorPhotoUrl!.isNotEmpty)
                          ? NetworkImage(post.authorPhotoUrl!)
                          : null,
                      child: Text(
                        post.username.isNotEmpty
                            ? post.username.substring(0, 1).toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.username,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color:
                                    theme.colorScheme.primary.withOpacity(0.08),
                              ),
                              child: Text(
                                post.isTextOnly ? 'Thought' : 'Moment',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          post.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: onSurface.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(IOSIcons.more),
                      onSelected: (value) async {
                        if (!isOwner) return;
                        try {
                          if (value == 'edit') {
                            await _editPost(context);
                          }
                          if (value == 'archive') {
                            await _archivePost(context);
                          }
                          if (value == 'delete') {
                            await _deletePost(context);
                          }
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
                    )
                  ],
                ),
              ),
              if (!post.isTextOnly && post.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(0),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: post.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                        if (post.isVideo)
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                      border: Border.all(
                        color:
                            theme.colorScheme.primary.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      post.text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked
                            ? IOSIcons.heartFill
                            : IOSIcons.heart,
                      ),
                      color: isLiked
                          ? Colors.redAccent
                          : theme.iconTheme.color,
                      onPressed: currentUserId == null
                          ? null
                          : () {
                              PostService.instance.toggleLike(
                                postId: post.id,
                                userId: currentUserId,
                              );

                              if (!isLiked) {
                                final me = AuthService.instance.currentUser;
                                NotificationService.instance.createNotification(
                                  toUserId: post.authorId,
                                  type: AppNotificationType.like,
                                  fromUserId: currentUserId,
                                  fromUsername: me?.email ?? 'user',
                                  postId: post.id,
                                );
                              }
                            },
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(IOSIcons.chat),
                      onPressed: () => _openComments(context),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(IOSIcons.share),
                      onPressed: () async {
                        final me = AuthService.instance.currentUser;
                        if (me == null) return;

                        await PostService.instance.repost(
                          sourcePostId: post.id,
                          newAuthorId: me.id,
                          newAuthorUsername: me.email,
                        );
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(IOSIcons.bookmark),
                      onPressed: () {},
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: Builder(
                  builder: (context) {
                    final likeCount = post.likeCount;
                    final commentCount = post.commentCount;
                    final shareCount = post.shareCount;

                    if (likeCount == 0 && commentCount == 0 && shareCount == 0) {
                      return Text(
                        'Be the first to like, comment or share',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurface.withOpacity(0.6),
                        ),
                      );
                    }

                    String likesLabel;
                    if (isLiked) {
                      if (likeCount == 0) {
                        likesLabel = 'Liked by you';
                      } else if (likeCount == 1) {
                        likesLabel = 'Liked by you';
                      } else {
                        final others = likeCount - 1;
                        likesLabel =
                            'Liked by you and $others other${others == 1 ? '' : 's'}';
                      }
                    } else {
                      if (likeCount == 0) {
                        likesLabel = '';
                      } else {
                        likesLabel =
                            '$likeCount like${likeCount == 1 ? '' : 's'}';
                      }
                    }

                    String commentsLabel = '';
                    if (commentCount > 0) {
                      commentsLabel =
                          '$commentCount comment${commentCount == 1 ? '' : 's'}';
                    }

                    String sharesLabel = '';
                    if (shareCount > 0) {
                      sharesLabel =
                          '$shareCount share${shareCount == 1 ? '' : 's'}';
                    }

                    final parts = <String>[
                      if (likesLabel.isNotEmpty) likesLabel,
                      if (commentsLabel.isNotEmpty) commentsLabel,
                      if (sharesLabel.isNotEmpty) sharesLabel,
                    ];

                    return Text(
                      parts.join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
