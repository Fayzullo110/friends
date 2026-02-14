import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/app_user.dart';
import '../../services/friend_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_detail_screen.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Friends')),
        body: const Center(child: Text('Please log in to see friends.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: StreamBuilder<List<String>>(
        stream: FriendService.instance.watchFriends(uid: user.uid),
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

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: ids)
                .snapshots(),
            builder: (context, usersSnap) {
              final docs = usersSnap.data?.docs ?? [];
              final friends = docs.map(AppUser.fromDoc).toList();

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
                      u.isOnline
                          ? 'Online'
                          : _formatLastSeen(u.lastActiveAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: u.isOnline
                            ? Colors.green
                            : theme.colorScheme.onSurface
                                .withOpacity(0.6),
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

String _formatLastSeen(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Last seen just now';
  if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
  if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
  return 'Last seen ${diff.inDays}d ago';
}
