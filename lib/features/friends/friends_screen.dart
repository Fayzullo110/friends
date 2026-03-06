import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/friend_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_detail_screen.dart';
import 'friend_requests_screen.dart';
import 'suggested_friends_screen.dart';
import 'close_friends_screen.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = AuthService.instance.currentUser;
    if (me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Friends')),
        body: const Center(child: Text('Please log in to see friends.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            tooltip: 'Suggested friends',
            icon: const Icon(Icons.explore_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SuggestedFriendsScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Close friends',
            icon: const Icon(Icons.star_border),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CloseFriendsScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Friend requests',
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FriendRequestsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: FriendService.instance.watchFriends(uid: me.id),
        builder: (context, snapshot) {
          final ids = snapshot.data ?? [];
          if (ids.isEmpty) {
            return Center(
              child: Text(
                'No friends yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }

          return FutureBuilder<List<AppUser>>(
            future: _loadUsers(ids),
            builder: (context, usersSnap) {
              final friends = usersSnap.data ?? [];

              return ListView.separated(
                itemCount: friends.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                ),
                itemBuilder: (context, index) {
                  final u = friends[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        u.username.isNotEmpty
                            ? u.username[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(u.username),
                    subtitle: Text(
                      _presenceText(u),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: u.isOnline
                            ? Colors.green
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    trailing: const Icon(Icons.chat_bubble_outline),
                    onTap: () async {
                      final me = await AuthService.instance.userChanges
                          .firstWhere((a) => a != null);
                      if (me == null) return;
                      final chatId = await ChatService.instance
                          .createOrGetDirectChat(me: me, other: u);
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            chatId: chatId,
                            title: u.username,
                            otherUserId: u.id,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

Future<List<AppUser>> _loadUsers(List<String> ids) async {
  if (ids.isEmpty) return <AppUser>[];
  final parsed = ids.map(int.parse).toList();
  final qs = parsed.join(',');
  final rows = await AuthService.instance.api.getListOfMaps('/api/users?ids=$qs');
  return rows.map(AppUser.fromJson).toList();
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
