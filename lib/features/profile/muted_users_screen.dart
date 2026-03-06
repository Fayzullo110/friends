import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/mute_service.dart';

class MutedUsersScreen extends StatefulWidget {
  const MutedUsersScreen({super.key});

  @override
  State<MutedUsersScreen> createState() => _MutedUsersScreenState();
}

class _MutedUsersScreenState extends State<MutedUsersScreen> {
  int? _mutedIdsSignature;
  Future<List<AppUser>>? _mutedUsersFuture;

  Future<List<AppUser>> _fetchUsersByIds(List<String> ids) async {
    final joined = ids.join(',');
    final rows = await AuthService.instance.api.getListOfMaps('/api/users?ids=$joined');
    return rows.map(AppUser.fromJson).toList();
  }

  @override
  Widget build(BuildContext context) {
    final current = AuthService.instance.currentUser;
    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Muted users')),
        body: const Center(
          child: Text('You need to be signed in to manage muted users.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Muted users')),
      body: StreamBuilder<List<String>>(
        stream: MuteService.instance.watchMuted(uid: current.id),
        builder: (context, snapshot) {
          final ids = snapshot.data ?? const <String>[];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ids.isEmpty) {
            return const Center(child: Text('You have not muted anyone.'));
          }

          final signature = Object.hashAll(ids);
          if (_mutedIdsSignature != signature || _mutedUsersFuture == null) {
            _mutedIdsSignature = signature;
            _mutedUsersFuture = _fetchUsersByIds(ids);
          }

          return FutureBuilder<List<AppUser>>(
            future: _mutedUsersFuture,
            builder: (context, usersSnap) {
              if (usersSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final muted = usersSnap.data ?? const <AppUser>[];
              if (muted.isEmpty) {
                return const Center(child: Text('You have not muted anyone.'));
              }

              return ListView.separated(
                itemCount: muted.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = muted[index];
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
                        await MuteService.instance.unmute(
                          fromUserId: current.id,
                          toUserId: user.id,
                        );
                      },
                      child: const Text('Unmute'),
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
