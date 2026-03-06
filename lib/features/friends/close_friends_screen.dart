import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/close_friends_service.dart';
import '../../services/user_cache_service.dart';
import '../../widgets/safe_network_image.dart';
import '../profile/user_profile_screen.dart';

class CloseFriendsScreen extends StatefulWidget {
  const CloseFriendsScreen({super.key});

  @override
  State<CloseFriendsScreen> createState() => _CloseFriendsScreenState();
}

class _CloseFriendsScreenState extends State<CloseFriendsScreen> {
  bool _loading = true;
  bool _saving = false;
  List<String> _ids = const [];

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final ids = await CloseFriendsService.instance.listOnce();
      if (mounted) {
        setState(() {
          _ids = ids;
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

  Future<void> _addFlow() async {
    final me = AuthService.instance.currentUser;
    if (me == null) return;

    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => const _AddCloseFriendSheet(),
    );
    if (id == null) return;
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      await CloseFriendsService.instance.add(userId: id);
      await _load();
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

  Future<void> _remove(String userId) async {
    if (_saving) return;
    setState(() {
      _saving = true;
    });
    try {
      await CloseFriendsService.instance.remove(userId: userId);
      await _load();
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Close friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: me == null || _saving ? null : _addFlow,
          ),
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
      body: me == null
          ? const Center(child: Text('Please log in to manage close friends.'))
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _ids.isEmpty
                  ? Center(
                      child: Text(
                        'No close friends yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    )
                  : FutureBuilder<List<AppUser>>(
                      future: Future.wait(
                        _ids.map((id) => UserCacheService.instance.get(id)),
                      ),
                      builder: (context, snap) {
                        final users = snap.data ?? const <AppUser>[];
                        return ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: theme.colorScheme.onSurface.withOpacity(0.08),
                          ),
                          itemBuilder: (context, index) {
                            final u = users[index];
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
                              trailing: IconButton(
                                tooltip: 'Remove',
                                icon: const Icon(Icons.close),
                                onPressed: _saving ? null : () => _remove(u.id),
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => UserProfileScreen(user: u),
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

class _AddCloseFriendSheet extends StatefulWidget {
  const _AddCloseFriendSheet();

  @override
  State<_AddCloseFriendSheet> createState() => _AddCloseFriendSheetState();
}

class _AddCloseFriendSheetState extends State<_AddCloseFriendSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  List<AppUser> _results = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = const [];
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final rows = await AuthService.instance.searchUsersByUsername(q);
      if (mounted) {
        setState(() {
          _results = rows;
        });
      }
    } catch (_) {
      // swallow
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
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: 'Search users',
                border: const OutlineInputBorder(),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _search,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            if (_results.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Type to search',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              )
            else
              SizedBox(
                height: 320,
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withOpacity(0.08),
                  ),
                  itemBuilder: (context, index) {
                    final u = _results[index];
                    return ListTile(
                      title: Text(u.username),
                      subtitle: u.firstName != null ? Text(u.firstName!) : null,
                      onTap: () => Navigator.of(context).pop(u.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
