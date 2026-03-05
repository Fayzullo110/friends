import 'package:flutter/material.dart';

import '../../models/reel.dart';
import '../../services/auth_service.dart';
import '../../services/reel_service.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/safe_network_image.dart';
import '../reels/reels_screen.dart';

class ArchivedReelsScreen extends StatelessWidget {
  const ArchivedReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = AuthService.instance.currentUser;

    if (me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Archived reels')),
        body: const Center(child: Text('Please log in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived reels'),
      ),
      body: StreamBuilder<List<Reel>>(
        stream: ReelService.instance.watchArchivedReels(uid: me.id),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <Reel>[];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No archived reels',
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
              final r = items[index];

              final String mediaLabel;
              if (r.mediaType == 'image') {
                mediaLabel = 'Image';
              } else if (r.mediaType == 'video') {
                mediaLabel = 'Video';
              } else {
                mediaLabel = 'Text';
              }

              return Card(
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReelsScreen(initialReelId: r.id),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    child: ClipOval(
                      child: (r.mediaType == 'image' &&
                              r.mediaUrl != null &&
                              r.mediaUrl!.trim().isNotEmpty)
                          ? SafeNetworkImage(
                              url: r.mediaUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Icon(
                                r.mediaType == 'video'
                                    ? IOSIcons.playCircleFill
                                    : IOSIcons.film,
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    r.caption.isEmpty ? '(no caption)' : r.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${r.archivedAt == null ? '' : 'Archived ${_formatTimeAgo(r.archivedAt!)}'}${r.archivedAt == null ? '' : ' · '}$mediaLabel',
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(IOSIcons.more),
                    onSelected: (value) async {
                      if (value == 'restore') {
                        await ReelService.instance.restoreReel(reelId: r.id);
                      }
                      if (value == 'delete') {
                        await ReelService.instance.deleteReel(reelId: r.id);
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
