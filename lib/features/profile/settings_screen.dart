import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme/ios_icons.dart';
import '../notifications/notifications_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'blocked_users_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: StreamBuilder<AppUser?>(
        stream: AuthService.instance.userChanges,
        builder: (context, snapshot) {
          final user = snapshot.data;

          return ListView(
            children: [
              const SizedBox(height: 8),
              if (user != null)
                ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : 'U',
                    ),
                  ),
                  title: Text(user.username),
                  subtitle: Text(user.email),
                  trailing: const Icon(IOSIcons.chevronRight),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(user: user),
                      ),
                    );
                  },
                )
              else
                const ListTile(
                  leading: Icon(IOSIcons.person),
                  title: Text('Not signed in'),
                  subtitle: Text('Sign in to manage your account.'),
                ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(IOSIcons.bell),
                title: const Text('Notifications'),
                subtitle: const Text('Mentions, follows, and activity'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(IOSIcons.shield),
                title: const Text('Privacy & safety'),
                subtitle:
                    const Text('Blocked users, interactions, and data usage'),
                onTap: () {
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please sign in to manage privacy settings.'),
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BlockedUsersScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(IOSIcons.lock),
                title: const Text('Security'),
                subtitle: const Text('Password and login activity'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(IOSIcons.settings),
                title: const Text('Appearance'),
                subtitle: Text(
                  'Follows system: ${theme.brightness == Brightness.dark ? 'Dark' : 'Light'}',
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Theme is controlled by system for now.'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(IOSIcons.globe),
                title: const Text('Language'),
                subtitle: const Text('English (default)'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Multiple languages are not supported yet.'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(IOSIcons.logout),
                title: const Text('Log out'),
                onTap: () async {
                  final current = FirebaseAuth.instance.currentUser;
                  if (current == null) return;
                  await AuthService.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(IOSIcons.questionCircle),
                title: const Text('Help & support'),
                subtitle: const Text('Report a problem or send feedback'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'For now, please send feedback through the app store or repo.',
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(IOSIcons.infoCircle),
                title: Text('About Friends'),
                subtitle: Text('Prototype social app designed by Fayzullo.'),
              ),
            ],
          );
        },
      ),
    );
  }
}
