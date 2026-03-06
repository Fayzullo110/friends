import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/post.dart';
import '../../services/follow_service.dart';
import '../../services/post_service.dart';
import '../../services/auth_service.dart';
import '../../services/block_service.dart';
import '../../services/mute_service.dart';
import '../../services/report_service.dart';
import '../../widgets/safe_network_image.dart';
import '../../theme/app_themes.dart';
import '../../theme/ios_icons.dart';

class UserProfileScreen extends StatefulWidget {
  final AppUser user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

String _presenceText(AppUser u) {
  if (u.isOnline) return 'Online';
  final dt = u.lastActiveAt;
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Last seen just now';
  if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
  if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
  return 'Last seen ${diff.inDays}d ago';
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isBlockedByMe = false;
  bool _isBlockedMe = false;
  bool _loadingBlockState = false;

  bool _isMuted = false;
  bool _loadingMuteState = false;

  @override
  void initState() {
    super.initState();
    _loadBlockState();
    _loadMuteState();
  }

  Future<void> _loadMuteState() async {
    final me = AuthService.instance.currentUser;
    if (me == null) return;

    setState(() {
      _loadingMuteState = true;
    });

    try {
      final muted = await MuteService.instance.isMuted(toUserId: widget.user.id);
      if (!mounted) return;
      setState(() {
        _isMuted = muted;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingMuteState = false;
        });
      }
    }
  }

  Future<void> _toggleMute() async {
    final me = AuthService.instance.currentUser;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to manage mutes.')),
      );
      return;
    }

    if (_isMuted) {
      await MuteService.instance.unmute(fromUserId: me.id, toUserId: widget.user.id);
      if (!mounted) return;
      setState(() {
        _isMuted = false;
      });
      return;
    }

    await MuteService.instance.mute(fromUserId: me.id, toUserId: widget.user.id);
    if (!mounted) return;
    setState(() {
      _isMuted = true;
    });
  }

  Future<void> _reportUser() async {
    final me = AuthService.instance.currentUser;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to report users.')),
      );
      return;
    }

    final reasonController = TextEditingController();
    final detailsController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report user'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'Details (optional)'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Report'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;
    final reason = reasonController.text.trim();
    final details = detailsController.text.trim();
    if (reason.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reason is required.')),
      );
      return;
    }

    await ReportService.instance.report(
      targetType: 'user',
      targetId: widget.user.id,
      reason: reason,
      details: details.isEmpty ? null : details,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted.')),
    );
  }

  Future<void> _loadBlockState() async {
    final me = AuthService.instance.currentUser;
    if (me == null) return;

    setState(() {
      _loadingBlockState = true;
    });

    try {
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
    final me = AuthService.instance.currentUser;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to manage blocks.')),
      );
      return;
    }

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
    final accent = AppThemes.seedFor(
      themeKey: widget.user.themeKey,
      themeSeedColor: widget.user.themeSeedColor,
    );
    final currentUser = AuthService.instance.currentUser;
    final isMe = currentUser != null && currentUser.id == widget.user.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.username.isEmpty
            ? 'Profile'
            : '@${widget.user.username}'),
        backgroundColor: accent.withOpacity(0.06),
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          if (!isMe)
            PopupMenuButton<String>(
              icon: const Icon(IOSIcons.moreVert),
              onSelected: (v) async {
                if (v == 'mute') {
                  await _toggleMute();
                } else if (v == 'report') {
                  await _reportUser();
                }
              },
              itemBuilder: (context) {
                final muteLabel = _loadingMuteState
                    ? 'Mute'
                    : (_isMuted ? 'Unmute' : 'Mute');
                return [
                  PopupMenuItem(
                    value: 'mute',
                    enabled: !_loadingMuteState,
                    child: Row(
                      children: [
                        const Icon(IOSIcons.volumeOff, size: 18),
                        const SizedBox(width: 8),
                        Text(muteLabel),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(IOSIcons.flag, size: 18),
                        SizedBox(width: 8),
                        Text('Report'),
                      ],
                    ),
                  ),
                ];
              },
            ),
        ],
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
                                  color: accent.withOpacity(0.7),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: widget.user.photoUrl != null
                                    ? SafeNetworkImage(
                                        url: widget.user.photoUrl,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 32,
                                        color: accent.withOpacity(0.9),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                widget.user.username,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (widget.user.isOfficial)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.verified,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            if ((widget.user.badgeType ?? '').trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.star,
                                  size: 18,
                                  color: theme.colorScheme.tertiary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: accent.withOpacity(0.35),
                            ),
                          ),
                          child: Text(
                            AppThemes.labelFor(
                              themeKey: widget.user.themeKey,
                              themeSeedColor: widget.user.themeSeedColor,
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (_presenceText(widget.user).isNotEmpty)
                          Text(
                            _presenceText(widget.user),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: widget.user.isOnline
                                  ? Colors.green
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.6),
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
        StreamBuilder<int>(
          stream:
              PostService.instance.watchPostCountByAuthor(authorId: user.id),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return _ProfileStat(label: 'Posts', value: count.toString());
          },
        ),
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
        stream: PostService.instance.watchPostsByAuthor(authorId: userId),
        builder: (context, snapshot) {
          final posts = snapshot.data ?? const <Post>[];

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
  bool _isRequested = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final current = AuthService.instance.currentUser;
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

      final isRequested = isFollowing
          ? false
          : await FollowService.instance.isRequested(
              fromUserId: me.id,
              toUserId: widget.target.id,
            );

      if (!mounted) return;
      setState(() {
        _isFollowing = isFollowing;
        _isRequested = isRequested;
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
    final current = AuthService.instance.currentUser;
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
      } else if (_isRequested) {
        await FollowService.instance.cancelRequest(
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
        if (_isFollowing) {
          _isFollowing = false;
          _isRequested = false;
        } else if (_isRequested) {
          _isRequested = false;
          _isFollowing = false;
        } else {
          // Follow on private account becomes requested, otherwise becomes following.
          if (widget.target.isPrivateAccount) {
            _isRequested = true;
            _isFollowing = false;
          } else {
            _isFollowing = true;
            _isRequested = false;
          }
        }
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
    final isRequested = _isRequested;
    final label = isFollowing ? 'Friends' : (isRequested ? 'Requested' : 'Add friend');
    return FilledButton.tonal(
      onPressed: _loading ? null : _toggle,
      child: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
