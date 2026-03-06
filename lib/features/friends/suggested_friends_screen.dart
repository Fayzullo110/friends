import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/discover_service.dart';
import '../../services/friend_service.dart';
import '../../widgets/safe_network_image.dart';
import '../profile/user_profile_screen.dart';

class SuggestedFriendsScreen extends StatefulWidget {
  const SuggestedFriendsScreen({super.key});

  @override
  State<SuggestedFriendsScreen> createState() => _SuggestedFriendsScreenState();
}

class _SuggestedFriendsScreenState extends State<SuggestedFriendsScreen> {
  bool _loading = true;
  List<AppUser> _items = const [];

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final rows = await DiscoverService.instance.getSuggestedUsers(limit: 50);
      if (mounted) {
        setState(() {
          _items = rows;
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggested friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: me == null
          ? const Center(child: Text('Please log in to see suggestions.'))
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? Center(
                      child: Text(
                        'No suggestions yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: theme.colorScheme.onSurface.withOpacity(0.08),
                      ),
                      itemBuilder: (context, index) {
                        final u = _items[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: ClipOval(
                              child: (u.photoUrl != null &&
                                      u.photoUrl!.trim().isNotEmpty)
                                  ? SafeNetworkImage(
                                      url: u.photoUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Text(
                                        u.username.isNotEmpty
                                            ? u.username[0].toUpperCase()
                                            : '?',
                                      ),
                                    ),
                            ),
                          ),
                          title: Text(u.username),
                          trailing: _AddFriendButton(user: u),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UserProfileScreen(user: u),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}

class _AddFriendButton extends StatefulWidget {
  final AppUser user;

  const _AddFriendButton({required this.user});

  @override
  State<_AddFriendButton> createState() => _AddFriendButtonState();
}

class _AddFriendButtonState extends State<_AddFriendButton> {
  bool _loading = false;
  bool _sent = false;

  Future<void> _send() async {
    if (_loading || _sent) return;
    final current = AuthService.instance.currentUser;
    if (current == null) return;

    setState(() {
      _loading = true;
    });

    try {
      await FriendService.instance.sendRequest(
        fromUserId: current.id,
        fromUsername: current.username,
        toUserId: widget.user.id,
      );
      if (mounted) {
        setState(() {
          _sent = true;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return TextButton(
      onPressed: _sent ? null : _send,
      child: Text(_sent ? 'Sent' : 'Add'),
    );
  }
}
