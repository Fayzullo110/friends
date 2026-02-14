import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/block_service.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final current = FirebaseAuth.instance.currentUser;
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
        stream: BlockService.instance.watchBlocked(uid: current.uid),
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

          // Firestore whereIn is limited to 10 elements; for simplicity we
          // fetch all users and filter client-side when list is small.
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = userSnap.data?.docs ?? [];
              final blocked = docs
                  .where((d) => ids.contains(d.id))
                  .map(AppUser.fromDoc)
                  .toList();

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
                        final me = await AuthService.instance.userChanges
                            .firstWhere((u) => u != null);
                        if (me == null) return;
                        await BlockService.instance.unblock(
                          fromUserId: me.id,
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
