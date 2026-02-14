import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/ios_icons.dart';
import '../../models/app_notification.dart';
import '../../services/notification_service.dart';
import '../../services/friend_service.dart';
import '../chat/video_player_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to see notifications.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationService.instance.watchMyNotifications(uid: user.uid),
        builder: (context, snapshot) {
          // Once the notifications are loaded, mark them as read.
          if (snapshot.hasData) {
            NotificationService.instance.markAllAsRead(uid: user.uid);
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final n = items[index];
              return _NotificationTile(notification: n, theme: theme);
            },
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withOpacity(0.08),
            ),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final ThemeData theme;

  const _NotificationTile({
    required this.notification,
    required this.theme,
  });

  IconData _iconForType() {
    switch (notification.type) {
      case AppNotificationType.like:
        return IOSIcons.heartFill;
      case AppNotificationType.comment:
        return IOSIcons.chatBubbleOutline;
      case AppNotificationType.friendRequest:
        return IOSIcons.personAdd;
      case AppNotificationType.friendAccepted:
        return IOSIcons.personFill;
      case AppNotificationType.follow:
        return IOSIcons.personAdd;
    }
  }

  Color _colorForType() {
    switch (notification.type) {
      case AppNotificationType.like:
        return Colors.pinkAccent;
      case AppNotificationType.comment:
        return theme.colorScheme.primary;
      case AppNotificationType.friendRequest:
        return Colors.blueAccent;
      case AppNotificationType.friendAccepted:
        return Colors.green;
      case AppNotificationType.follow:
        return theme.colorScheme.primary;
    }
  }

  String _text() {
    final name = notification.fromUsername.isNotEmpty
        ? notification.fromUsername
        : 'Someone';
    switch (notification.type) {
      case AppNotificationType.like:
        return '$name liked your content';
      case AppNotificationType.comment:
        return '$name commented on your content';
      case AppNotificationType.friendRequest:
        return '$name sent you a friend request';
      case AppNotificationType.friendAccepted:
        return '$name accepted your friend request';
      case AppNotificationType.follow:
        return '$name started following you';
    }
  }

  Future<void> _openContent(BuildContext context) async {
    final id = notification.postId;
    if (id == null || id.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ContentDetailScreen(contentId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType();
    return ListTile(
      onTap: notification.type == AppNotificationType.friendRequest
          ? null
          : () => _openContent(context),
      leading:
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(notification.fromUserId)
            .get(),
        builder: (context, snap) {
          String? photoUrl;
          if (snap.hasData && snap.data!.exists) {
            final data = snap.data!.data();
            photoUrl = data?['photoUrl'] as String?;
          }

          return CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Icon(
                    _iconForType(),
                    color: color,
                  )
                : null,
          );
        },
      ),
      title: Text(_text()),
      subtitle: Text(_formatTimeAgo(notification.createdAt)),
      trailing: notification.type == AppNotificationType.friendRequest
          ? _FriendRequestActions(notification: notification)
          : (notification.postId != null && notification.postId!.isNotEmpty)
              ? _ContentThumb(contentId: notification.postId!)
              : null,
    );
  }
}

class _ContentThumb extends StatelessWidget {
  final String contentId;

  const _ContentThumb({required this.contentId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget placeholder() {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(
          IOSIcons.photo,
          size: 18,
          color: theme.colorScheme.onSurface.withOpacity(0.55),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('posts').doc(contentId).get(),
      builder: (context, postSnap) {
        if (postSnap.connectionState == ConnectionState.waiting) {
          return placeholder();
        }

        if (postSnap.hasData && postSnap.data!.exists) {
          final data = postSnap.data!.data() ?? <String, dynamic>{};
          final mediaUrl = data['mediaUrl'] as String?;
          final mediaType = data['mediaType'] as String? ?? 'text';
          if (mediaUrl == null || mediaUrl.isEmpty) {
            return placeholder();
          }
          return _thumbForMedia(
            context,
            mediaUrl: mediaUrl,
            isVideo: mediaType == 'video',
          );
        }

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future:
              FirebaseFirestore.instance.collection('reels').doc(contentId).get(),
          builder: (context, reelSnap) {
            if (reelSnap.connectionState == ConnectionState.waiting) {
              return placeholder();
            }
            if (reelSnap.hasData && reelSnap.data!.exists) {
              final data = reelSnap.data!.data() ?? <String, dynamic>{};
              final mediaUrl = data['mediaUrl'] as String?;
              final mediaType = data['mediaType'] as String? ?? 'video';
              if (mediaUrl == null || mediaUrl.isEmpty) {
                return placeholder();
              }
              return _thumbForMedia(
                context,
                mediaUrl: mediaUrl,
                isVideo: mediaType == 'video',
              );
            }
            return placeholder();
          },
        );
      },
    );
  }

  Widget _thumbForMedia(
    BuildContext context, {
    required String mediaUrl,
    required bool isVideo,
  }) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Image.network(
            mediaUrl,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                width: 44,
                height: 44,
                color: theme.colorScheme.onSurface.withOpacity(0.06),
              );
            },
          ),
          if (isVideo)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.2),
                alignment: Alignment.center,
                child: const Icon(
                  IOSIcons.playCircleFill,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContentDetailScreen extends StatelessWidget {
  final String contentId;

  const _ContentDetailScreen({required this.contentId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('posts').doc(contentId).get(),
        builder: (context, postSnap) {
          if (postSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          if (postSnap.hasData && postSnap.data!.exists) {
            final data = postSnap.data!.data() ?? <String, dynamic>{};
            final author = data['authorUsername'] as String? ?? 'user';
            final text = data['text'] as String? ?? '';
            final mediaUrl = data['mediaUrl'] as String?;
            final mediaType = data['mediaType'] as String? ?? 'text';
            return _buildContentBody(
              context,
              title: 'Post',
              author: author,
              text: text,
              mediaUrl: mediaUrl,
              mediaType: mediaType,
            );
          }

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future:
                FirebaseFirestore.instance.collection('reels').doc(contentId).get(),
            builder: (context, reelSnap) {
              if (reelSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (reelSnap.hasData && reelSnap.data!.exists) {
                final data = reelSnap.data!.data() ?? <String, dynamic>{};
                final author = data['authorUsername'] as String? ?? 'user';
                final caption = data['caption'] as String? ?? '';
                final mediaUrl = data['mediaUrl'] as String?;
                final mediaType = data['mediaType'] as String? ?? 'video';
                return _buildContentBody(
                  context,
                  title: 'Reel',
                  author: author,
                  text: caption,
                  mediaUrl: mediaUrl,
                  mediaType: mediaType,
                );
              }

              return Center(
                child: Text(
                  'Content not available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContentBody(
    BuildContext context, {
    required String title,
    required String author,
    required String text,
    required String? mediaUrl,
    required String mediaType,
  }) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@$author',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        if (text.isNotEmpty)
          Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
          const SizedBox(height: 12),
          if (mediaType == 'video')
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.onSurface.withOpacity(0.08),
              ),
              alignment: Alignment.center,
              child: IconButton(
                iconSize: 56,
                icon: const Icon(IOSIcons.playCircle),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(url: mediaUrl),
                    ),
                  );
                },
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                mediaUrl,
                height: 320,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 220,
                    color: theme.colorScheme.onSurface.withOpacity(0.06),
                    alignment: Alignment.center,
                    child: const Icon(IOSIcons.brokenImage),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

class _FriendRequestActions extends StatelessWidget {
  final AppNotification notification;

  const _FriendRequestActions({required this.notification});

  Future<void> _handleAction(BuildContext context, bool accept) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to manage requests.')),
      );
      return;
    }

    try {
      final uid = authUser.uid;

      final snap = await FirebaseFirestore.instance
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: notification.fromUserId)
          .where('toUserId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This request is no longer available.')),
        );
        return;
      }

      final requestId = snap.docs.first.id;

      if (accept) {
        await FriendService.instance.acceptRequest(requestId);

        await NotificationService.instance.createNotification(
          toUserId: notification.fromUserId,
          type: AppNotificationType.friendAccepted,
          fromUserId: uid,
          fromUsername: authUser.email ?? 'user',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted.')),
        );
      } else {
        await FriendService.instance.rejectRequest(requestId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request declined.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => _handleAction(context, false),
          child: const Text('Decline'),
        ),
        const SizedBox(width: 4),
        FilledButton.tonal(
          onPressed: () => _handleAction(context, true),
          child: const Text('Accept'),
        ),
      ],
    );
  }
}

String _formatTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}
