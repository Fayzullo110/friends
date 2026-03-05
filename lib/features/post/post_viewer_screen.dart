import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/post.dart';
import '../../models/comment.dart';
import '../../services/auth_service.dart';
import '../../services/comment_service.dart';
import '../../services/post_service.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/safe_network_image.dart';
import '../chat/video_player_screen.dart';

class PostViewerScreen extends StatefulWidget {
  final List<Post> posts;
  final int initialIndex;

  const PostViewerScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<PostViewerScreen> createState() => _PostViewerScreenState();
}

class _PostViewerScreenState extends State<PostViewerScreen> {
  late final PageController _controller;
  int _index = 0;

  final Map<String, bool> _likedOverride = {};
  final Map<String, int> _likeCountOverride = {};
  final Set<String> _savedPostIds = {};

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.posts.length - 1);
    _controller = PageController(initialPage: _index);
  }

  Future<void> _share(Post post) async {
    try {
      await PostService.instance.incrementShareCount(postId: post.id);

      final url = post.mediaUrl;
      final text = (post.text).trim();
      final payload = [
        if (text.isNotEmpty) text,
        if (url != null && url.trim().isNotEmpty) url,
      ].join('\n');

      if (payload.trim().isNotEmpty) {
        await Share.share(payload, subject: 'Friends');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shared')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share')),
      );
    }
  }

  void _toggleSave(Post post) {
    setState(() {
      if (_savedPostIds.contains(post.id)) {
        _savedPostIds.remove(post.id);
      } else {
        _savedPostIds.add(post.id);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleLike(Post post) async {
    final me = AuthService.instance.currentUser;
    if (me == null) return;

    final currentlyLiked = _likedOverride[post.id] ?? post.likedBy.contains(me.id);
    final currentCount = _likeCountOverride[post.id] ?? post.likeCount;

    setState(() {
      _likedOverride[post.id] = !currentlyLiked;
      _likeCountOverride[post.id] = currentlyLiked ? (currentCount - 1) : (currentCount + 1);
    });

    try {
      await PostService.instance.toggleLike(postId: post.id, userId: me.id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _likedOverride[post.id] = currentlyLiked;
        _likeCountOverride[post.id] = currentCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to like post')),
      );
    }
  }

  void _openComments(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        return _PostCommentsSheet(
          postId: post.id,
          postAuthorId: post.authorId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.posts.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, index) {
          final post = widget.posts[index];
          final meId = AuthService.instance.currentUser?.id;
          final isLiked = _likedOverride[post.id] ?? (meId != null && post.likedBy.contains(meId));
          final likeCount = _likeCountOverride[post.id] ?? post.likeCount;
          final isSaved = _savedPostIds.contains(post.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.12),
                        child: ClipOval(
                          child: (post.authorPhotoUrl != null &&
                                  post.authorPhotoUrl!.trim().isNotEmpty)
                              ? SafeNetworkImage(
                                  url: post.authorPhotoUrl,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Text(
                                    post.authorUsername.isNotEmpty
                                        ? post.authorUsername
                                            .substring(0, 1)
                                            .toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorUsername,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _formatTimeAgo(post.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _share(post),
                        icon: const Icon(IOSIcons.shareUp),
                        tooltip: 'Share',
                      ),
                      IconButton(
                        onPressed: () => _toggleSave(post),
                        icon: Icon(
                          isSaved
                              ? IOSIcons.bookmarkFill
                              : IOSIcons.bookmark,
                        ),
                        tooltip: isSaved ? 'Saved' : 'Save',
                      ),
                    ],
                  ),
                ),
                if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          onTap: post.mediaType == 'video'
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => VideoPlayerScreen(
                                        url: post.mediaUrl!,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: SafeNetworkImage(
                            url: post.mediaUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (post.mediaType == 'video')
                          const Center(
                            child: Icon(
                              IOSIcons.playCircleFill,
                              size: 54,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (post.text.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      post.text,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _toggleLike(post),
                        icon: Icon(
                          isLiked ? IOSIcons.heartFill : IOSIcons.heart,
                          color: isLiked ? Colors.redAccent : null,
                        ),
                      ),
                      Text('$likeCount'),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _openComments(post),
                        icon: const Icon(IOSIcons.chatBubbleOutline),
                      ),
                      Text('${post.commentCount}'),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _share(post),
                        icon: const Icon(IOSIcons.shareUp),
                      ),
                      Text('${post.shareCount}'),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PostCommentsSheet extends StatefulWidget {
  final String postId;
  final String postAuthorId;

  const _PostCommentsSheet({
    required this.postId,
    required this.postAuthorId,
  });

  @override
  State<_PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<_PostCommentsSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final me = AuthService.instance.currentUser;
    if (me == null) return;
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await CommentService.instance.addComment(
        postId: widget.postId,
        authorId: me.id,
        authorUsername: me.email,
        text: trimmed,
      );
      _controller.clear();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send comment')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      final comments = snapshot.data ?? const <Comment>[];

                      if (comments.isEmpty) {
                        return Center(
                          child: Text(
                            'No comments yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        itemBuilder: (context, index) {
                          final c = comments[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    theme.colorScheme.primary.withOpacity(0.12),
                                child: ClipOval(
                                  child: (c.authorPhotoUrl != null &&
                                          c.authorPhotoUrl!.trim().isNotEmpty)
                                      ? SafeNetworkImage(
                                          url: c.authorPhotoUrl,
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
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
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.authorUsername,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (c.type == CommentType.text)
                                      Text(
                                        c.text,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          height: 1.25,
                                        ),
                                      )
                                    else if (c.type == CommentType.gif && c.mediaUrl != null && c.mediaUrl!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SafeNetworkImage(
                                          url: c.mediaUrl,
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
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(999)),
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_submitting)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
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
        ),
      ),
    );
  }
}

String _formatTimeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}
