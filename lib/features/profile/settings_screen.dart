import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme/ios_icons.dart';
import '../notifications/notifications_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'privacy_safety_screen.dart';
import 'archived_posts_screen.dart';
import 'archived_reels_screen.dart';
import 'follow_requests_screen.dart';
import 'theme_presets_screen.dart';
import 'admin_badges_screen.dart';

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
                leading: const Icon(IOSIcons.personAdd),
                title: const Text('Follow requests'),
                subtitle: const Text('Approve or decline who follows you'),
                onTap: () {
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please sign in to manage follow requests.'),
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FollowRequestsScreen(),
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
                      builder: (_) => const PrivacySafetyScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(IOSIcons.bookmark),
                title: const Text('Archived posts'),
                subtitle: const Text('Restore or delete archived posts'),
                onTap: () {
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please sign in to view archived posts.'),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ArchivedPostsScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(IOSIcons.film),
                title: const Text('Archived reels'),
                subtitle: const Text('Restore or delete archived reels'),
                onTap: () {
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please sign in to view archived reels.'),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ArchivedReelsScreen(),
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ThemePresetsScreen(),
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
                  await AuthService.instance.logout();
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
              ListTile(
                leading: const Icon(IOSIcons.shield),
                title: const Text('Admin tools'),
                subtitle: const Text('Badges and verification'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminBadgesScreen(),
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
