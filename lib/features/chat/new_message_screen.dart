import 'dart:async';

import 'package:flutter/material.dart';

import 'chat_detail_screen.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/block_service.dart';
import '../../widgets/safe_network_image.dart';

class NewMessageScreen extends StatefulWidget {
  final bool startInGroupMode;

  const NewMessageScreen({
    super.key,
    this.startInGroupMode = false,
  });

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  final TextEditingController _groupTitleController = TextEditingController();
  final Set<String> _selectedUserIds = <String>{};
  late bool _isGroupMode;

  Timer? _debounce;

  String? _searchFutureForUserId;
  String? _searchFutureForQuery;
  Future<List<AppUser>>? _searchFuture;

  @override
  void initState() {
    super.initState();
    _isGroupMode = widget.startInGroupMode;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _groupTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final meNow = AuthService.instance.currentUser;
    if (meNow == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('New message')),
        body: const Center(child: Text('Please log in to start a chat.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isGroupMode ? 'New group' : 'New message'),
        actions: [
          IconButton(
            tooltip: _isGroupMode ? 'Direct message mode' : 'New group chat',
            icon: Icon(
              _isGroupMode ? Icons.person_outline : Icons.group_add_outlined,
            ),
            onPressed: () {
              setState(() {
                _isGroupMode = !_isGroupMode;
                _selectedUserIds.clear();
                _groupTitleController.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  if (!mounted) return;
                  setState(() {
                    _query = v;
                  });
                });
              },
              decoration: InputDecoration(
                hintText: 'Search people',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<AppUser?>(
              stream: AuthService.instance.userChanges,
              builder: (context, meSnap) {
                final me = meSnap.data;
                if (me == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return FutureBuilder<List<AppUser>>(
                  future: () {
                    final q = _query;
                    if (_searchFutureForUserId != me.id ||
                        _searchFutureForQuery != q ||
                        _searchFuture == null) {
                      _searchFutureForUserId = me.id;
                      _searchFutureForQuery = q;
                      _searchFuture = ChatService.instance.searchUsers(
                        query: q,
                        excludeUid: me.id,
                      );
                    }
                    return _searchFuture;
                  }(),
                  builder: (context, snapshot) {
                    final filtered = snapshot.data ?? [];

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'No users found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      );
                    }

                    // Direct message mode: simple list, tap to open chat.
                    if (!_isGroupMode) {
                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final u = filtered[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: theme.colorScheme.primary
                                  .withOpacity(0.12),
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
                                              : 'U',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            title: Text(
                              u.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(u.email),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              // Prevent chatting when there is a block in either direction.
                              final eitherBlocked =
                                  await BlockService.instance.isBlocked(
                                        fromUserId: me.id,
                                        toUserId: u.id,
                                      ) ||
                                      await BlockService.instance.isBlocked(
                                        fromUserId: u.id,
                                        toUserId: me.id,
                                      );
                              if (eitherBlocked) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'You can\'t start a chat because there is a block between you.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final chatId = await ChatService.instance
                                  .createOrGetDirectChat(
                                me: me,
                                other: u,
                              );
                              if (!context.mounted) return;
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(
                                    chatId: chatId,
                                    title: u.username,
                                    otherUserId: u.id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }

                    // Group mode: multi-select + group name + create button.
                    final selectedUsers = filtered
                        .where((u) => _selectedUserIds.contains(u.id))
                        .toList();

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 0),
                            itemBuilder: (context, index) {
                              final u = filtered[index];
                              final isSelected =
                                  _selectedUserIds.contains(u.id);
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: theme
                                      .colorScheme.primary
                                      .withOpacity(0.12),
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
                                                  : 'U',
                                              style: TextStyle(
                                                color: theme
                                                    .colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                title: Text(
                                  u.username,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(u.email),
                                trailing: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.disabledColor,
                                ),
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedUserIds.remove(u.id);
                                    } else {
                                      _selectedUserIds.add(u.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        if (selectedUsers.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: _buildGroupChatActions(
                              context: context,
                              me: me,
                              users: selectedUsers,
                            ),
                          ),
                      ],
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

  Widget _buildGroupChatActions({
    required BuildContext context,
    required AppUser me,
    required List<AppUser> users,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _groupTitleController,
          decoration: const InputDecoration(
            labelText: 'Group name',
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            final title = _groupTitleController.text.trim().isEmpty
                ? 'Group chat'
                : _groupTitleController.text.trim();
            // Prevent creating group chats that include users with a block in
            // either direction with the current user.
            for (final u in users) {
              final eitherBlocked =
                  await BlockService.instance.isBlocked(
                        fromUserId: me.id,
                        toUserId: u.id,
                      ) ||
                      await BlockService.instance.isBlocked(
                        fromUserId: u.id,
                        toUserId: me.id,
                      );
              if (eitherBlocked) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Can\'t create group: there is a block between you and ${u.username}.',
                    ),
                  ),
                );
                return;
              }
            }

            final chatId = await ChatService.instance.createGroupChat(
              me: me,
              others: users,
              title: title,
            );

            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  chatId: chatId,
                  title: title,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Text('Create group with ${users.length} people'),
        ),
      ],
    );
  }
}
