import 'package:flutter/material.dart';

import '../../models/story.dart';
import '../../models/story_highlight.dart';
import '../../services/story_highlight_service.dart';

class HighlightEditScreen extends StatefulWidget {
  final StoryHighlight highlight;

  const HighlightEditScreen({super.key, required this.highlight});

  @override
  State<HighlightEditScreen> createState() => _HighlightEditScreenState();
}

class _HighlightEditScreenState extends State<HighlightEditScreen> {
  late final TextEditingController _titleController;
  bool _loading = true;
  bool _saving = false;

  List<Story> _stories = const <Story>[];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.highlight.title);
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final stories = await StoryHighlightService.instance
          .getHighlightStoriesOnce(highlightId: widget.highlight.id);
      if (!mounted) return;
      setState(() {
        _stories = stories;
      });
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

  Future<void> _saveTitle() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _saving = true;
    });

    try {
      await StoryHighlightService.instance.renameHighlight(
        highlightId: widget.highlight.id,
        title: title,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _deleteHighlight() async {
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
      await StoryHighlightService.instance.deleteHighlight(
        highlightId: widget.highlight.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _removeStory(Story story) async {
    try {
      await StoryHighlightService.instance.removeStoryFromHighlight(
        highlightId: widget.highlight.id,
        storyId: story.id,
      );
      if (!mounted) return;
      setState(() {
        _stories = _stories.where((s) => s.id != story.id).toList();
      });
      await StoryHighlightService.instance.reorderHighlightItems(
        highlightId: widget.highlight.id,
        orderedStoryIds: _stories.map((e) => e.id).toList(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _persistReorder() async {
    try {
      await StoryHighlightService.instance.reorderHighlightItems(
        highlightId: widget.highlight.id,
        orderedStoryIds: _stories.map((e) => e.id).toList(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reorder: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit highlight'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveTitle,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Stories',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _deleteHighlight,
                        child: const Text('Delete highlight'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: _stories.length,
                      onReorder: (oldIndex, newIndex) async {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _stories.removeAt(oldIndex);
                          _stories.insert(newIndex, item);
                        });
                        await _persistReorder();
                      },
                      itemBuilder: (context, index) {
                        final s = _stories[index];
                        final subtitle = s.mediaType == 'text'
                            ? (s.text ?? '')
                            : (s.mediaUrl ?? '');
                        return ListTile(
                          key: ValueKey('story_${s.id}'),
                          title: Text(
                            s.mediaType == 'text'
                                ? (s.text ?? '').trim().isEmpty
                                    ? 'Text story'
                                    : (s.text!).trim()
                                : '${s.mediaType} story',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: 'Remove',
                            onPressed: () => _removeStory(s),
                          ),
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
