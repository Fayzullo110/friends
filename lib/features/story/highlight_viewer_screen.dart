import 'package:flutter/material.dart';

import '../../models/story.dart';
import '../../models/story_highlight.dart';
import '../../services/story_highlight_service.dart';
import '../../services/auth_service.dart';
import 'highlight_edit_screen.dart';
import 'story_viewer_screen.dart';

class HighlightViewerScreen extends StatelessWidget {
  final StoryHighlight highlight;

  const HighlightViewerScreen({super.key, required this.highlight});

  bool _isMine() {
    final me = AuthService.instance.currentUser;
    if (me == null) return false;
    return highlight.ownerId == me.id;
  }

  Future<void> _deleteHighlight(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete highlight'),
          content: const Text('This will remove the highlight from your profile.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    try {
      await StoryHighlightService.instance.deleteHighlight(highlightId: highlight.id);
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = _isMine();
    return FutureBuilder<List<Story>>(
      future: StoryHighlightService.instance
          .getHighlightStoriesOnce(highlightId: highlight.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(highlight.title),
              actions: [
                if (mine)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => HighlightEditScreen(highlight: highlight),
                          ),
                        );
                        if (changed == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Highlight updated.')),
                          );
                        }
                      }
                      if (value == 'delete') {
                        await _deleteHighlight(context);
                      }
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            body: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final stories = snap.data ?? const <Story>[];
        if (stories.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(highlight.title),
              actions: [
                if (mine)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => HighlightEditScreen(highlight: highlight),
                          ),
                        );
                        if (changed == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Highlight updated.')),
                          );
                        }
                      }
                      if (value == 'delete') {
                        await _deleteHighlight(context);
                      }
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            body: const Center(child: Text('No stories in this highlight.')),
          );
        }

        return StoryViewerScreen(
          stories: stories,
          initialIndex: 0,
        );
      },
    );
  }
}
