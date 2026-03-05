import 'package:flutter/material.dart';

import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/safe_network_image.dart';

class ArchivedPostsScreen extends StatelessWidget {
  const ArchivedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = AuthService.instance.currentUser;

    if (me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Archived posts')),
        body: const Center(child: Text('Please log in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived posts'),
      ),
      body: StreamBuilder<List<Post>>(
        stream: PostService.instance.watchArchivedPosts(uid: me.id),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <Post>[];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No archived posts',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final p = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: ClipOval(
                      child: (p.authorPhotoUrl != null &&
                              p.authorPhotoUrl!.trim().isNotEmpty)
                          ? SafeNetworkImage(
                              url: p.authorPhotoUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                p.authorUsername.isNotEmpty
                                    ? p.authorUsername[0].toUpperCase()
                                    : 'U',
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    p.text.isEmpty ? '(no text)' : p.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    p.archivedAt == null
                        ? ''
                        : 'Archived ${_formatTimeAgo(p.archivedAt!)}',
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(IOSIcons.more),
                    onSelected: (value) async {
                      if (value == 'restore') {
                        await PostService.instance.restorePost(postId: p.id);
                      }
                      if (value == 'delete') {
                        await PostService.instance.deletePost(postId: p.id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'restore',
                        child: Text('Restore'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
