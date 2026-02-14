import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import '../../models/post.dart';
import '../../services/follow_service.dart';
import '../../services/post_service.dart';
import '../../services/auth_service.dart';
import '../../services/block_service.dart';

class UserProfileScreen extends StatefulWidget {
  final AppUser user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isBlockedByMe = false;
  bool _isBlockedMe = false;
  bool _loadingBlockState = false;

  @override
  void initState() {
    super.initState();
    _loadBlockState();
  }

  Future<void> _loadBlockState() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;

    setState(() {
      _loadingBlockState = true;
    });

    try {
      final me = await AuthService.instance.userChanges.firstWhere(
        (u) => u != null,
      );
      if (me == null) return;

      final blockedByMe = await BlockService.instance.isBlocked(
        fromUserId: me.id,
        toUserId: widget.user.id,
      );
      final blockedMe = await BlockService.instance.isBlocked(
        fromUserId: widget.user.id,
        toUserId: me.id,
      );

      if (!mounted) return;
      setState(() {
        _isBlockedByMe = blockedByMe;
        _isBlockedMe = blockedMe;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingBlockState = false;
        });
      }
    }
  }

  Future<void> _toggleBlock() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to manage blocks.')),
      );
      return;
    }

    final me = await AuthService.instance.userChanges.firstWhere(
      (u) => u != null,
    );
    if (me == null) return;

    if (_isBlockedByMe) {
      await BlockService.instance.unblock(
        fromUserId: me.id,
        toUserId: widget.user.id,
      );
      if (!mounted) return;
      setState(() {
        _isBlockedByMe = false;
      });
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Block user'),
          content: Text(
            'Block @${widget.user.username}? They will not be able to follow or interact with you.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Block'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await BlockService.instance.block(
      fromUserId: me.id,
      toUserId: widget.user.id,
    );
    if (!mounted) return;
    setState(() {
      _isBlockedByMe = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMe = currentUser != null && currentUser.uid == widget.user.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.username.isEmpty
            ? 'Profile'
            : '@${widget.user.username}'),
      ),
      body: Container(
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
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.surfaceVariant,
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: widget.user.photoUrl != null
                                    ? Image.network(
                                        widget.user.photoUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 32,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.8),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: _HeaderStats(user: widget.user),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.user.username,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if ((widget.user.bio ?? '').isNotEmpty)
                          Text(
                            widget.user.bio!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                        const SizedBox(height: 14),
                        if (!isMe)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (!_isBlockedByMe)
                                _ProfileFollowButton(target: widget.user),
                              const SizedBox(width: 8),
                              FilledButton.tonal(
                                onPressed:
                                    _loadingBlockState ? null : _toggleBlock,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _isBlockedByMe
                                      ? Theme.of(context)
                                          .colorScheme
                                          .errorContainer
                                      : null,
                                ),
                                child: _loadingBlockState
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _isBlockedByMe ? 'Unblock' : 'Block',
                                      ),
                              ),
                            ],
                          ),
                        if (!isMe && _isBlockedByMe)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'You blocked this user.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ),
                        if (!isMe && _isBlockedMe && !_isBlockedByMe)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'This user has blocked you.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Posts',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            _UserPostsSliver(userId: widget.user.id),
          ],
        ),
      ),
    );
  }
}

class _HeaderStats extends StatelessWidget {
  final AppUser user;

  const _HeaderStats({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _ProfileStat(label: 'Posts', value: '0'),
        _FollowersStat(user: user),
        _FollowingStat(user: user),
      ],
    );
  }
}

class _UserPostsSliver extends StatelessWidget {
  final String userId;

  const _UserPostsSliver({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: StreamBuilder<List<Post>>(
        stream: PostService.instance
            .watchRecentPosts(), // filter client-side for now
        builder: (context, snapshot) {
          final posts =
              (snapshot.data ?? []).where((p) => p.authorId == userId).toList();

          if (posts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No posts yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final p = posts[index];
              return ListTile(
                title: Text(p.text),
                subtitle: Text(
                  '${p.likeCount} likes',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _FollowersStat extends StatelessWidget {
  final AppUser user;

  const _FollowersStat({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: FollowService.instance.watchFollowers(uid: user.id),
      builder: (context, snapshot) {
        final ids = snapshot.data ?? const [];
        return _ProfileStat(
          label: 'Followers',
          value: ids.length.toString(),
        );
      },
    );
  }
}

class _FollowingStat extends StatelessWidget {
  final AppUser user;

  const _FollowingStat({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: FollowService.instance.watchFollowing(uid: user.id),
      builder: (context, snapshot) {
        final ids = snapshot.data ?? const [];
        return _ProfileStat(
          label: 'Following',
          value: ids.length.toString(),
        );
      },
    );
  }
}

class _ProfileFollowButton extends StatefulWidget {
  final AppUser target;

  const _ProfileFollowButton({required this.target});

  @override
  State<_ProfileFollowButton> createState() => _ProfileFollowButtonState();
}

class _ProfileFollowButtonState extends State<_ProfileFollowButton> {
  bool _loading = false;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final me = await AuthService.instance.userChanges.firstWhere(
        (u) => u != null,
      );
      if (me == null) return;

      final isFollowing = await FollowService.instance.isFollowing(
        fromUserId: me.id,
        toUserId: widget.target.id,
      );

      if (!mounted) return;
      setState(() {
        _isFollowing = isFollowing;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggle() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to follow users.')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final me = await AuthService.instance.userChanges.firstWhere(
        (u) => u != null,
      );
      if (me == null) return;

      if (_isFollowing) {
        await FollowService.instance.unfollow(
          fromUserId: me.id,
          toUserId: widget.target.id,
        );
      } else {
        await FollowService.instance.follow(
          fromUserId: me.id,
          toUserId: widget.target.id,
        );
      }

      if (!mounted) return;
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update follow state: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFollowing = _isFollowing;
    return FilledButton.tonal(
      onPressed: _loading ? null : _toggle,
      child: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(isFollowing ? 'Friends' : 'Add friend'),
    );
  }
}
