import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/follow_service.dart';
import '../../services/user_cache_service.dart';

class FollowRequestsScreen extends StatefulWidget {
  const FollowRequestsScreen({super.key});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthService.instance.currentUser;

    if (me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Follow requests')),
        body: const Center(child: Text('Please log in to see follow requests.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Outgoing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RequestsList(
            emptyText: 'No incoming requests',
            idsStream: FollowService.instance.watchIncomingRequests(uid: me.id),
            builder: (ctx, userId) => _IncomingRequestTile(userId: userId),
          ),
          _RequestsList(
            emptyText: 'No outgoing requests',
            idsStream: FollowService.instance.watchOutgoingRequests(uid: me.id),
            builder: (ctx, userId) => _OutgoingRequestTile(userId: userId),
          ),
        ],
      ),
    );
  }
}

typedef _TileBuilder = Widget Function(BuildContext context, String userId);

class _RequestsList extends StatelessWidget {
  final String emptyText;
  final Stream<List<String>> idsStream;
  final _TileBuilder builder;

  const _RequestsList({
    required this.emptyText,
    required this.idsStream,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<String>>(
      stream: idsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final ids = (snapshot.data ?? const <String>[]).where((e) => e.trim().isNotEmpty).toList();
        if (ids.isEmpty) {
          return Center(
            child: Text(
              emptyText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: ids.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: theme.colorScheme.onSurface.withOpacity(0.08),
          ),
          itemBuilder: (context, index) {
            final id = ids[index];
            return builder(context, id);
          },
        );
      },
    );
  }
}

class _IncomingRequestTile extends StatefulWidget {
  final String userId;

  const _IncomingRequestTile({required this.userId});

  @override
  State<_IncomingRequestTile> createState() => _IncomingRequestTileState();
}

class _IncomingRequestTileState extends State<_IncomingRequestTile> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() {
      _loading = true;
    });

    try {
      await FollowService.instance.acceptRequest(followerId: widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request accepted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _decline() async {
    setState(() {
      _loading = true;
    });

    try {
      await FollowService.instance.declineRequest(followerId: widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request declined')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline: $e')),
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
    return _UserTile(
      userId: widget.userId,
      subtitle: const Text('Wants to follow you'),
      trailing: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _accept,
                  child: const Text('Accept'),
                ),
                TextButton(
                  onPressed: _decline,
                  child: const Text('Decline'),
                ),
              ],
            ),
    );
  }
}

class _OutgoingRequestTile extends StatefulWidget {
  final String userId;

  const _OutgoingRequestTile({required this.userId});

  @override
  State<_OutgoingRequestTile> createState() => _OutgoingRequestTileState();
}

class _OutgoingRequestTileState extends State<_OutgoingRequestTile> {
  bool _loading = false;

  Future<void> _cancel() async {
    final me = AuthService.instance.currentUser;
    if (me == null) return;

    setState(() {
      _loading = true;
    });

    try {
      await FollowService.instance.cancelRequest(fromUserId: me.id, toUserId: widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request canceled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel: $e')),
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
    return _UserTile(
      userId: widget.userId,
      subtitle: const Text('Waiting for approval'),
      trailing: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: _cancel,
              child: const Text('Cancel'),
            ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String userId;
  final Widget? subtitle;
  final Widget? trailing;

  const _UserTile({
    required this.userId,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<AppUser>(
      future: UserCacheService.instance.get(userId),
      builder: (context, snapshot) {
        final u = snapshot.data;
        final username = u?.username ?? '';
        final title = username.isNotEmpty ? username : 'User $userId';
        final initial = username.isNotEmpty ? username.substring(0, 1).toUpperCase() : 'U';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: Text(
              initial,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(title),
          subtitle: subtitle,
          trailing: trailing,
        );
      },
    );
  }
}
