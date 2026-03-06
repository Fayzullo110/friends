import 'package:flutter/material.dart';

import '../../models/notification_preferences.dart';
import '../../services/notification_preferences_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  NotificationPreferences? _prefs;

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final p = await NotificationPreferencesService.instance.getMyPreferences();
      if (mounted) {
        setState(() {
          _prefs = p;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _save({
    bool? notifyLikes,
    bool? notifyComments,
    bool? notifyFriendRequests,
    bool? notifyFriendAccepted,
    bool? notifyFollows,
    bool? digestEnabled,
  }) async {
    if (_saving) return;
    setState(() {
      _saving = true;
    });
    try {
      final next = await NotificationPreferencesService.instance
          .updateMyPreferences(
        notifyLikes: notifyLikes,
        notifyComments: notifyComments,
        notifyFriendRequests: notifyFriendRequests,
        notifyFriendAccepted: notifyFriendAccepted,
        notifyFollows: notifyFollows,
        digestEnabled: digestEnabled,
      );
      if (mounted) {
        setState(() {
          _prefs = next;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _prefs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification settings'),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : prefs == null
              ? const Center(child: Text('Failed to load preferences.'))
              : ListView(
                  children: [
                    SwitchListTile(
                      title: const Text('Digest mode'),
                      subtitle: const Text(
                        'Group notifications into a compact summary view',
                      ),
                      value: prefs.digestEnabled,
                      onChanged: (v) => _save(digestEnabled: v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Likes'),
                      value: prefs.notifyLikes,
                      onChanged: (v) => _save(notifyLikes: v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Comments'),
                      value: prefs.notifyComments,
                      onChanged: (v) => _save(notifyComments: v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Friend requests'),
                      value: prefs.notifyFriendRequests,
                      onChanged: (v) => _save(notifyFriendRequests: v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Friend accepted'),
                      value: prefs.notifyFriendAccepted,
                      onChanged: (v) => _save(notifyFriendAccepted: v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Follows'),
                      value: prefs.notifyFollows,
                      onChanged: (v) => _save(notifyFollows: v),
                    ),
                    const Divider(height: 1),
                  ],
                ),
    );
  }
}
