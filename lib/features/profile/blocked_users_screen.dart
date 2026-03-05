import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/block_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  int? _blockedIdsSignature;
  Future<List<AppUser>>? _blockedUsersFuture;

  Future<List<AppUser>> _fetchUsersByIds(List<String> ids) async {
    final joined = ids.join(',');
    final rows = await AuthService.instance.api
        .getListOfMaps('/api/users?ids=$joined');
    return rows.map(AppUser.fromJson).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? current = AuthService.instance.currentUser;
    if (current == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Blocked users'),
        ),
        body: const Center(
          child: Text('You need to be signed in to manage blocked users.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked users'),
      ),
      body: StreamBuilder<List<String>>(
        stream: BlockService.instance.watchBlocked(uid: current.id),
        builder: (context, snapshot) {
          final ids = snapshot.data ?? const [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ids.isEmpty) {
            return const Center(
              child: Text('You have not blocked anyone.'),
            );
          }

          final signature = Object.hashAll(ids);
          if (_blockedIdsSignature != signature || _blockedUsersFuture == null) {
            _blockedIdsSignature = signature;
            _blockedUsersFuture = _fetchUsersByIds(ids);
          }

          return FutureBuilder<List<AppUser>>(
            future: _blockedUsersFuture,
            builder: (context, usersSnap) {
              if (usersSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final blocked = usersSnap.data ?? const <AppUser>[];
              if (blocked.isEmpty) {
                return const Center(
                  child: Text('You have not blocked anyone.'),
                );
              }

              return ListView.separated(
                itemCount: blocked.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = blocked[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        user.username.isNotEmpty
                            ? user.username[0].toUpperCase()
                            : 'U',
                      ),
                    ),
                    title: Text('@${user.username}'),
                    subtitle: Text(user.email),
                    trailing: TextButton(
                      onPressed: () async {
                        await BlockService.instance.unblock(
                          fromUserId: current.id,
                          toUserId: user.id,
                        );
                      },
                      child: const Text('Unblock'),
                    ),
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
