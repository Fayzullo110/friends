import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/friend_service.dart';
import '../../services/block_service.dart';
import '../profile/user_profile_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<AppUser> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final users = await AuthService.instance.searchUsersByUsername(query);

      // If logged in, filter out users I have blocked AND users who have
      // blocked me (best-effort using Firestore reads per user).
      final current = AuthService.instance.currentUser;
      List<AppUser> visibleUsers = users;
      if (current != null) {
        final myBlockedIds =
            await BlockService.instance.getBlockedOnce(uid: current.id);

        final futures = users.map((u) async {
          // Skip users I have blocked.
          if (myBlockedIds.contains(u.id)) {
            return null;
          }

          // Check if this user has blocked me.
          final blockedMe = await BlockService.instance.isBlocked(
            fromUserId: u.id,
            toUserId: current.id,
          );
          return blockedMe ? null : u;
        }).toList();

        final filtered = await Future.wait(futures);
        visibleUsers = filtered.whereType<AppUser>().toList();
      }

      if (!mounted) return;
      setState(() {
        _results = visibleUsers;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.searchFailed(e.toString()) ?? 'Search failed: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchUsersTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  _search();
                });
              },
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: l10n.searchByUsername,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _controller.clear();
                              _debounce?.cancel();
                              setState(() {
                                _results = [];
                              });
                            },
                          )
                        : null),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: theme.colorScheme.onSurface.withOpacity(0.08),
              ),
              itemBuilder: (context, index) {
                final u = _results[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (u.photoUrl != null &&
                            u.photoUrl!.isNotEmpty)
                        ? NetworkImage(u.photoUrl!)
                        : null,
                    child: (u.photoUrl == null || u.photoUrl!.isEmpty)
                        ? Text(
                            u.username.isNotEmpty
                                ? u.username[0].toUpperCase()
                                : '?',
                          )
                        : null,
                  ),
                  title: Text(u.username),
                  subtitle:
                      u.firstName != null ? Text(u.firstName!) : null,
                  trailing: _FollowButton(user: u),
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
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatefulWidget {
  final AppUser user;

  const _FollowButton({required this.user});

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _loading = false;
  bool _sent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    return;
  }

  Future<void> _toggle() async {
    final current = AuthService.instance.currentUser;
    if (current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add friends.')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final me = await AuthService.instance.userChanges.firstWhere(
        (u) => u != null,
      );
      if (me == null) return;

      await FriendService.instance.sendRequest(
        fromUserId: me.id,
        fromUsername: me.username,
        toUserId: widget.user.id,
      );

      if (!mounted) return;
      setState(() {
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
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
    return TextButton.icon(
      onPressed: _loading ? null : _toggle,
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_sent ? Icons.check : Icons.person_add_alt_1),
      label: Text(_sent ? 'Request sent' : 'Add friend'),
    );
  }
}
