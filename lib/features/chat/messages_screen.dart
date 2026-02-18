import 'package:flutter/material.dart';

import 'chat_detail_screen.dart';
import 'new_message_screen.dart';
import '../friends/user_search_screen.dart';
import '../status/create_status_screen.dart';
import '../status/status_viewer_screen.dart';
import '../../models/chat.dart';
import '../../models/user_status.dart';
import '../../models/app_user.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/follow_service.dart';
import '../../services/user_status_service.dart';
import '../../theme/ios_icons.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final me = AuthService.instance.currentUser;
    if (me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: const Center(child: Text('Please log in to use messages.')),
      );
    }

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor:
            isDark ? theme.appBarTheme.backgroundColor : Colors.white,
        foregroundColor:
            isDark ? theme.appBarTheme.foregroundColor : Colors.black,
        elevation: isDark ? 1 : 0,
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(IOSIcons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const UserSearchScreen(),
                ),
              );
            },
            tooltip: 'Search users',
          ),
          IconButton(
            icon: const Icon(IOSIcons.personAdd),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NewMessageScreen(startInGroupMode: true),
                ),
              );
            },
            tooltip: 'New group',
          ),
          IconButton(
            icon: const Icon(IOSIcons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NewMessageScreen(),
                ),
              );
            },
            tooltip: 'New message',
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 0),
          SizedBox(
            height: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Friends',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildFriendsRow(context, theme, me.id),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Chats', 'chats'),
                const SizedBox(width: 8),
                _buildFilterChip('Groups', 'groups'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Chat>>(
              stream: ChatService.instance.watchMyChats(uid: me.id),
              builder: (context, snapshot) {
                var chats = snapshot.data ?? [];
                if (_filter == 'chats') {
                  chats = chats.where((c) => !c.isGroup).toList();
                } else if (_filter == 'groups') {
                  chats = chats.where((c) => c.isGroup).toList();
                }
                if (chats.isEmpty) {
                  // Still show Saved messages entry even if there are no other chats.
                  return ListView.separated(
                    itemCount: 1,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      return _buildSavedMessagesTile(context, theme);
                    },
                  );
                }

                return ListView.separated(
                  itemCount: chats.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildSavedMessagesTile(context, theme);
                    }
                    final c = chats[index - 1];
                    final otherId = c.members.firstWhere(
                      (m) => m != me.id,
                      orElse: () => me.id,
                    );
                    final title = c.memberUsernames[otherId] ?? 'Chat';

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: c.isGroup
                          ? CircleAvatar(
                              radius: 22,
                              backgroundColor: theme.colorScheme.primary
                                  .withOpacity(0.08),
                              child: Text(
                                title.isNotEmpty
                                    ? title[0].toUpperCase()
                                    : 'C',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : FutureBuilder<AppUser>(
                              future: AuthService.instance.api.getJson(
                                '/api/users/$otherId',
                                (json) => AppUser.fromJson(json),
                              ),
                              builder: (context, snap) {
                                final u = snap.data;
                                final photoUrl = u?.photoUrl;
                                return CircleAvatar(
                                  radius: 22,
                                  backgroundColor: theme
                                      .colorScheme.primary
                                      .withOpacity(0.08),
                                  foregroundImage:
                                      (photoUrl != null && photoUrl.isNotEmpty)
                                          ? NetworkImage(photoUrl)
                                          : null,
                                  child: Text(
                                    title.isNotEmpty
                                        ? title[0].toUpperCase()
                                        : 'C',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        c.lastMessage.isEmpty ? 'Say hi' : c.lastMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            TimeOfDay.fromDateTime(c.updatedAt)
                                .format(context),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              chatId: c.id,
                              title: title,
                              otherUserId: c.isGroup ? null : otherId,
                            ),
                          ),
                        );
                      },
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

  Widget _buildFilterChip(String label, String value) {
    final theme = Theme.of(context);
    final selected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? const Color(0xFF8D5CF6) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsRow(BuildContext context, ThemeData theme, String currentUserId) {
    return FutureBuilder<List<String>>(
      future: _getFollowingIds(currentUserId),
      builder: (context, followingSnapshot) {
        final followingIds = followingSnapshot.data ?? [];

        return StreamBuilder<List<UserStatus>>(
          stream: UserStatusService.instance.watchFriendsStatuses(
            currentUserId: currentUserId,
            followingIds: followingIds.isEmpty ? [currentUserId] : followingIds,
          ),
          builder: (context, snapshot) {
            final statuses = snapshot.data ?? [];

            // Build the list including "My Status" as first item
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: statuses.isEmpty ? 1 : statuses.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  // My Status slot
                  return _buildMyStatusItem(context, theme, currentUserId);
                }

                final status = statuses[index - 1];
                final isMyStatus = status.userId == currentUserId;

                if (isMyStatus) {
                  // Skip my status in the list since we already have it as first item
                  return const SizedBox.shrink();
                }

                return _buildStatusItem(context, theme, status);
              },
            );
          },
        );
      },
    );
  }

  Future<List<String>> _getFollowingIds(String userId) async {
    try {
      return await FollowService.instance.getFollowingOnce(uid: userId);
    } catch (e) {
      return [];
    }
  }

  Widget _buildMyStatusItem(BuildContext context, ThemeData theme, String userId) {
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<UserStatus?>(
      stream: UserStatusService.instance.watchMyStatus(userId),
      builder: (context, snapshot) {
        final hasStatus = snapshot.hasData && snapshot.data != null;

        return GestureDetector(
          onTap: () {
            if (hasStatus) {
              // View my status
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StatusViewerScreen(
                    statuses: [snapshot.data!],
                    initialIndex: 0,
                  ),
                ),
              );
            } else {
              // Create new status
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreateStatusScreen(),
                ),
              );
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasStatus
                      ? const LinearGradient(
                          colors: [Color(0xFFFE8BCD), Color(0xFF8D5CF6)],
                        )
                      : null,
                  color: hasStatus ? null : theme.colorScheme.surface,
                  border: hasStatus
                      ? null
                      : Border.all(
                          color: theme.dividerColor,
                          width: 2,
                        ),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: isDark
                      ? theme.colorScheme.surfaceVariant
                      : Colors.white,
                  child: hasStatus && snapshot.data!.hasEmoji
                      ? Text(
                          snapshot.data!.emoji!,
                          style: const TextStyle(fontSize: 20),
                        )
                      : const Icon(
                          IOSIcons.add,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'My Status',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(BuildContext context, ThemeData theme, UserStatus status) {
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = AuthService.instance.currentUser?.id;
    final isSeen = currentUserId != null && status.seenBy.contains(currentUserId);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StatusViewerScreen(
              statuses: [status],
              initialIndex: 0,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Dashed purple circle border like the reference
          CustomPaint(
            painter: DashedCirclePainter(
              color: isSeen ? Colors.grey : const Color(0xFF8D5CF6),
              strokeWidth: 2.5,
              dashLength: 6,
              gapLength: 4,
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: isDark
                    ? theme.colorScheme.surfaceVariant
                    : Colors.grey.shade200,
                backgroundImage: status.photoUrl != null
                    ? NetworkImage(status.photoUrl!)
                    : null,
                child: status.photoUrl == null
                    ? Text(
                        status.username.isNotEmpty
                            ? status.username[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            status.username,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  Widget _buildSavedMessagesTile(BuildContext context, ThemeData theme) {
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        child: Icon(
          IOSIcons.bookmark,
          color: theme.colorScheme.primary,
        ),
      ),
      title: const Text(
        'Saved messages',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text('Your private space'),
      onTap: () async {
        try {
          final meNow = AuthService.instance.currentUser;
          if (meNow == null) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please log in to use Saved messages.')),
            );
            return;
          }

          final me = await AuthService.instance.userChanges.firstWhere(
            (u) => u != null,
          );
          if (me == null) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Could not load your user profile.')),
            );
            return;
          }

          final chatId = await ChatService.instance.createOrGetSelfChat(me: me);
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                chatId: chatId,
                title: 'Saved messages',
              ),
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open Saved messages: $e')),
          );
        }
      },
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final circumference = 2 * 3.14159 * radius;
    final dashCount = (circumference / (dashLength + gapLength)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * (dashLength + gapLength) / circumference) * 2 * 3.14159;
      final sweepAngle = (dashLength / circumference) * 2 * 3.14159;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle - 3.14159 / 2,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
