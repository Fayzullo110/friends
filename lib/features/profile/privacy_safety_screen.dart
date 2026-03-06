import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme/ios_icons.dart';
import 'blocked_users_screen.dart';
import 'muted_users_screen.dart';

class PrivacySafetyScreen extends StatefulWidget {
  const PrivacySafetyScreen({super.key});

  @override
  State<PrivacySafetyScreen> createState() => _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState extends State<PrivacySafetyScreen> {
  bool _saving = false;

  Future<void> _save({bool? isPrivateAccount, String? commentPolicy}) async {
    if (_saving) return;
    setState(() {
      _saving = true;
    });
    try {
      await AuthService.instance.updatePrivacySafety(
        isPrivateAccount: isPrivateAccount,
        commentPolicy: commentPolicy,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & safety'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: StreamBuilder<AppUser?>(
        stream: AuthService.instance.userChanges,
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) {
            return const Center(
              child: Text('Please sign in to manage privacy settings.'),
            );
          }

          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Private account'),
                subtitle: const Text('Only approved followers can see your content'),
                value: user.isPrivateAccount,
                onChanged: (v) => _save(isPrivateAccount: v),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(IOSIcons.chatBubbleOutline),
                title: const Text('Who can comment'),
                subtitle: Text(user.commentPolicy),
                onTap: () async {
                  final next = await showModalBottomSheet<String>(
                    context: context,
                    showDragHandle: true,
                    builder: (ctx) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Everyone'),
                              onTap: () => Navigator.of(ctx).pop('everyone'),
                            ),
                            ListTile(
                              title: const Text('Followers'),
                              onTap: () => Navigator.of(ctx).pop('followers'),
                            ),
                            ListTile(
                              title: const Text('No one'),
                              onTap: () => Navigator.of(ctx).pop('no_one'),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  );
                  if (next == null) return;
                  await _save(commentPolicy: next);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(IOSIcons.shield),
                title: const Text('Blocked users'),
                trailing: const Icon(IOSIcons.chevronRight),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(IOSIcons.volumeOff),
                title: const Text('Muted users'),
                trailing: const Icon(IOSIcons.chevronRight),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MutedUsersScreen()),
                  );
                },
              ),
              const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }
}
