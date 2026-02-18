import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/friend_service.dart';

class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = AuthService.instance.currentUser;
    if (me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Friend requests')),
        body: const Center(child: Text('Please log in to see requests.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend requests'),
      ),
      body: StreamBuilder<List<FriendRequest>>(
        stream: FriendService.instance.watchIncoming(uid: me.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? const <FriendRequest>[];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No requests',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withOpacity(0.08),
            ),
            itemBuilder: (context, index) {
              final r = items[index];
              return _RequestTile(request: r);
            },
          );
        },
      ),
    );
  }
}

class _RequestTile extends StatefulWidget {
  final FriendRequest request;

  const _RequestTile({required this.request});

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() {
      _loading = true;
    });

    try {
      await FriendService.instance.acceptRequest(widget.request.id);
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

  Future<void> _reject() async {
    setState(() {
      _loading = true;
    });

    try {
      await FriendService.instance.rejectRequest(widget.request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject: $e')),
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
    final theme = Theme.of(context);
    final r = widget.request;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
        child: Text(
          r.fromUsername.isNotEmpty ? r.fromUsername.substring(0, 1).toUpperCase() : 'U',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(r.fromUsername.isNotEmpty ? r.fromUsername : 'User ${r.fromUserId}'),
      subtitle: const Text('Sent you a friend request'),
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
                  onPressed: _reject,
                  child: const Text('Reject'),
                ),
              ],
            ),
    );
  }
}
