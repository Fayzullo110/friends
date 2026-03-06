import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';

import '../../models/story_sticker.dart';
import '../../services/story_service.dart';
import '../../services/auth_service.dart';
import '../../services/story_draft_service.dart';
import '../../theme/ios_icons.dart';
import '../../widgets/safe_network_image.dart';
import '../chat/gif_picker_sheet.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

enum _StoryType { text, image, video, gif }

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  _StoryType _type = _StoryType.text;
  XFile? _selectedMedia;
  String? _gifUrl;
  bool _submitting = false;
  String? _musicTitle;
  String? _musicArtist;
  String? _musicUrl;

  final List<StorySticker> _stickers = <StorySticker>[];
  int _nextStickerLocalId = 1;

  bool _draftLoaded = false;
  bool _suppressDraftSave = false;

  @override
  void dispose() {
    _textController.removeListener(_onDraftChanged);
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onDraftChanged);
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    if (_draftLoaded) return;
    _draftLoaded = true;

    try {
      final draft = await StoryDraftService.instance.load();
      if (!mounted) return;
      if (draft == null || draft.isEmpty) return;

      final restore = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Restore draft?'),
            content: const Text('You have an unfinished story draft.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Discard'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Restore'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      if (restore != true) {
        await StoryDraftService.instance.clear();
        return;
      }

      _suppressDraftSave = true;
      setState(() {
        final typeStr = (draft['type'] as String?) ?? 'text';
        _type = switch (typeStr) {
          'image' => _StoryType.image,
          'video' => _StoryType.video,
          'gif' => _StoryType.gif,
          _ => _StoryType.text,
        };

        _gifUrl = (draft['gifUrl'] as String?);
        _musicTitle = draft['musicTitle'] as String?;
        _musicArtist = draft['musicArtist'] as String?;
        _musicUrl = draft['musicUrl'] as String?;

        _stickers
          ..clear()
          ..addAll(
            ((draft['stickers'] as List<dynamic>?) ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(StorySticker.fromJson),
          );

        final mediaPath = (draft['mediaPath'] as String?) ?? '';
        if (mediaPath.trim().isNotEmpty && !kIsWeb) {
          _selectedMedia = XFile(mediaPath);
        } else {
          _selectedMedia = null;
        }
      });
      _textController.text = (draft['text'] as String?) ?? '';
    } catch (_) {
      // swallow
    } finally {
      _suppressDraftSave = false;
    }
  }

  Future<void> _saveDraft() async {
    if (_suppressDraftSave) return;
    if (_submitting) return;

    final text = _textController.text.trim();
    final hasMedia = _selectedMedia != null;
    final hasGif = (_gifUrl ?? '').trim().isNotEmpty;
    final hasMusic = (_musicUrl ?? '').trim().isNotEmpty;

    final isEmpty =
        text.isEmpty && !hasMedia && !hasGif && !hasMusic && _type == _StoryType.text;
    if (isEmpty) {
      await StoryDraftService.instance.clear();
      return;
    }

    final String typeStr = switch (_type) {
      _StoryType.image => 'image',
      _StoryType.video => 'video',
      _StoryType.gif => 'gif',
      _StoryType.text => 'text',
    };

    final draft = <String, dynamic>{
      'type': typeStr,
      'text': text,
      'gifUrl': _gifUrl,
      'musicTitle': _musicTitle,
      'musicArtist': _musicArtist,
      'musicUrl': _musicUrl,
      'stickers': _stickers.map((s) => s.toJson()).toList(),
      if (!kIsWeb) 'mediaPath': _selectedMedia?.path,
    };
    await StoryDraftService.instance.save(draft);
  }

  void _onDraftChanged() {
    _saveDraft();
  }

  Future<void> _discardDraft() async {
    setState(() {
      _type = _StoryType.text;
      _selectedMedia = null;
      _gifUrl = null;
      _musicTitle = null;
      _musicArtist = null;
      _musicUrl = null;
      _stickers.clear();
    });
    _textController.clear();
    await StoryDraftService.instance.clear();
  }

  Future<void> _addSticker() async {
    if (_submitting) return;

    final theme = Theme.of(context);

    final type = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.poll_outlined),
                title: const Text('Poll'),
                onTap: () => Navigator.of(ctx).pop('poll'),
              ),
              ListTile(
                leading: const Icon(IOSIcons.chatBubbleOutline),
                title: const Text('Question'),
                onTap: () => Navigator.of(ctx).pop('question'),
              ),
              ListTile(
                leading: const Icon(Icons.local_fire_department_outlined),
                title: const Text('Emoji slider'),
                onTap: () => Navigator.of(ctx).pop('emoji_slider'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || type == null) return;

    String? dataJson;
    if (type == 'poll') {
      final q = TextEditingController();
      final a = TextEditingController();
      final b = TextEditingController();
      try {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Poll'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: q,
                    decoration: const InputDecoration(labelText: 'Question'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: a,
                    decoration: const InputDecoration(labelText: 'Option 1'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: b,
                    decoration: const InputDecoration(labelText: 'Option 2'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );

        if (ok != true) return;

        final question = q.text.trim();
        final o1 = a.text.trim();
        final o2 = b.text.trim();
        if (question.isEmpty || o1.isEmpty || o2.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all poll fields.')),
          );
          return;
        }

        dataJson = jsonEncode({
          'question': question,
          'options': [o1, o2],
        });
      } finally {
        q.dispose();
        a.dispose();
        b.dispose();
      }
    } else if (type == 'question') {
      final prompt = TextEditingController();
      try {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Question'),
              content: TextField(
                controller: prompt,
                decoration: const InputDecoration(labelText: 'Prompt'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
        if (ok != true) return;
        final p = prompt.text.trim();
        if (p.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prompt cannot be empty.')),
          );
          return;
        }
        dataJson = jsonEncode({'prompt': p});
      } finally {
        prompt.dispose();
      }
    } else if (type == 'emoji_slider') {
      final label = TextEditingController();
      String emoji = '🔥';
      try {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (context, setLocalState) {
                return AlertDialog(
                  title: const Text('Emoji slider'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text('Emoji:'),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: emoji,
                            items: const ['🔥', '❤️', '😂', '😮', '👏', '💯']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setLocalState(() {
                                emoji = v;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: label,
                        decoration: const InputDecoration(
                          labelText: 'Label (optional)',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Add'),
                    ),
                  ],
                );
              },
            );
          },
        );
        if (ok != true) return;
        dataJson = jsonEncode({
          'emoji': emoji,
          'label': label.text.trim(),
        });
      } finally {
        label.dispose();
      }
    }

    if (!mounted) return;
    final id = 'local_${_nextStickerLocalId++}';
    setState(() {
      _stickers.add(
        StorySticker(
          id: id,
          type: type,
          posX: 0.5,
          posY: 0.35,
          dataJson: dataJson,
        ),
      );
    });
    await _saveDraft();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          type == 'poll'
              ? 'Poll sticker added.'
              : type == 'question'
                  ? 'Question sticker added.'
                  : 'Emoji slider added.',
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  Future<void> _pickMedia() async {
    final source = ImageSource.gallery;
    XFile? picked;
    if (_type == _StoryType.image) {
      picked = await _picker.pickImage(source: source);
    } else if (_type == _StoryType.video) {
      picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 5),
      );
    }
    if (picked == null) return;

    setState(() {
      _selectedMedia = picked;
      _gifUrl = null;
    });
    await _saveDraft();
  }

  Future<void> _pickMusic() async {
    final theme = Theme.of(context);

    final tracks = [
      const (
        "Chill wave",
        "Lo-Fi Collective",
        "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
      ),
      const (
        "Sunset drive",
        "Indie Beats",
        "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
      ),
      const (
        "Night city",
        "Synth Lines",
        "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
      ),
    ];

    final previewPlayer = AudioPlayer();
    try {
      String query = '';
      String? playingUrl;
      bool isLoading = false;

      final result = await showModalBottomSheet<(String, String, String)?>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final q = query.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? tracks
                  : tracks.where((t) {
                      return t.$1.toLowerCase().contains(q) ||
                          t.$2.toLowerCase().contains(q);
                    }).toList();

              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Add music',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: TextField(
                          onChanged: (v) => setSheetState(() => query = v),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(IOSIcons.search),
                            hintText: 'Search music',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Flexible(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text('No results'),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final t = filtered[index];
                                  final isPlaying = playingUrl == t.$3;
                                  return ListTile(
                                    leading: IconButton(
                                      icon: isLoading && isPlaying
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(
                                              isPlaying
                                                  ? IOSIcons.pause
                                                  : IOSIcons.play,
                                            ),
                                      onPressed: () async {
                                        if (isLoading) return;
                                        try {
                                          if (isPlaying) {
                                            await previewPlayer.pause();
                                            setSheetState(() {
                                              playingUrl = null;
                                            });
                                            return;
                                          }

                                          setSheetState(() {
                                            isLoading = true;
                                          });
                                          await previewPlayer.stop();
                                          await previewPlayer.setUrl(t.$3);
                                          await previewPlayer.play();
                                          setSheetState(() {
                                            playingUrl = t.$3;
                                          });
                                        } catch (_) {
                                          setSheetState(() {
                                            playingUrl = null;
                                          });
                                          ScaffoldMessenger.of(ctx)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Failed to preview this track.'),
                                            ),
                                          );
                                        } finally {
                                          setSheetState(() {
                                            isLoading = false;
                                          });
                                        }
                                      },
                                    ),
                                    title: Text(t.$1),
                                    subtitle: Text(t.$2),
                                    onTap: () async {
                                      await previewPlayer.stop();
                                      if (ctx.mounted) {
                                        Navigator.of(ctx).pop(t);
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                      if (playingUrl != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                          child: Row(
                            children: [
                              const Icon(IOSIcons.musicNote, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Previewing…',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await previewPlayer.stop();
                                  setSheetState(() {
                                    playingUrl = null;
                                  });
                                },
                                child: const Text('Stop'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (result == null) return;
      setState(() {
        _musicTitle = result.$1;
        _musicArtist = result.$2;
        _musicUrl = result.$3;
      });
      await _saveDraft();
    } finally {
      await previewPlayer.dispose();
    }
  }

  Future<void> _pickGif() async {
    final url = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GifPickerSheet(
          onSelected: (gif) {
            Navigator.of(ctx).pop(gif.originalUrl);
          },
        );
      },
    );

    if (url == null || url.isEmpty) return;
    setState(() {
      _gifUrl = url;
      _selectedMedia = null;
      _type = _StoryType.gif;
    });
    await _saveDraft();
  }

  Future<void> _submit() async {
    final me = AuthService.instance.currentUser;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to share a story.')),
      );
      return;
    }

    final text = _textController.text.trim();

    if ((_type == _StoryType.image || _type == _StoryType.video) &&
        _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an image or video.')),
      );
      return;
    }

    if (_type == _StoryType.gif && (_gifUrl == null || _gifUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a GIF.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      if (_type == _StoryType.gif) {
        await StoryService.instance.createMediaStory(
          authorId: me.id,
          authorUsername: me.username,
          mediaUrl: _gifUrl!,
          mediaType: 'gif',
          text: text.isEmpty ? null : text,
          musicTitle: _musicTitle,
          musicArtist: _musicArtist,
          musicUrl: _musicUrl,
          stickers: _stickers,
        );
      } else {
        final bytes = await _selectedMedia!.readAsBytes();
        final upload = await AuthService.instance.api.uploadFile(
          path: '/api/uploads',
          bytes: bytes,
          filename: _selectedMedia!.name,
        );
        final mediaUrl = (upload['url'] as String?) ?? '';
        if (mediaUrl.isEmpty) throw Exception('Upload failed');

        final isVideo = _type == _StoryType.video;

        await StoryService.instance.createMediaStory(
          authorId: me.id,
          authorUsername: me.username,
          mediaUrl: mediaUrl,
          mediaType: isVideo ? 'video' : 'image',
          text: text.isEmpty ? null : text,
          musicTitle: _musicTitle,
          musicArtist: _musicArtist,
          musicUrl: _musicUrl,
          stickers: _stickers,
        );
      }

      if (!mounted) return;
      await StoryDraftService.instance.clear();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story shared.')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty
                ? 'Failed to share story. Please try again.'
                : message,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create story'),
        actions: [
          IconButton(
            tooltip: 'Discard draft',
            onPressed: _submitting
                ? null
                : () async {
                    await _discardDraft();
                  },
            icon: const Icon(IOSIcons.delete),
          ),
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Share'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                _buildTypeChip(theme, _StoryType.image, 'Image'),
                _buildTypeChip(theme, _StoryType.video, 'Short video (5s)'),
                _buildTypeChip(theme, _StoryType.gif, 'GIF'),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Caption / text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _musicTitle == null
                      ? TextButton.icon(
                          onPressed: _pickMusic,
                          icon: const Icon(IOSIcons.musicNote),
                          label: const Text('Add music (optional)'),
                        )
                      : InkWell(
                          onTap: _pickMusic,
                          child: Row(
                            children: [
                              const Icon(IOSIcons.musicNote, size: 20),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _musicTitle!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_musicArtist != null)
                                      Text(
                                        _musicArtist!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _musicTitle = null;
                                    _musicArtist = null;
                                    _musicUrl = null;
                                  });
                                },
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStoryCanvas(theme),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _addSticker,
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    _stickers.isEmpty
                        ? 'Add sticker'
                        : 'Add sticker (${_stickers.length})',
                  ),
                ),
                const SizedBox(width: 10),
                if (_stickers.isNotEmpty)
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            setState(() {
                              _stickers.clear();
                            });
                            await _saveDraft();
                          },
                    child: const Text('Clear stickers'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (_type == _StoryType.image || _type == _StoryType.video)
              OutlinedButton.icon(
                onPressed: _pickMedia,
                icon: const Icon(IOSIcons.folder),
                label: Text(
                  _type == _StoryType.image
                      ? 'Choose image from gallery'
                      : 'Choose video (max 5s)',
                ),
              )
            else if (_type == _StoryType.gif)
              OutlinedButton.icon(
                onPressed: _pickGif,
                icon: const Icon(IOSIcons.gif),
                label: const Text('Choose GIF'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCanvas(ThemeData theme) {
    final bg = _buildCanvasBackground(theme);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              fit: StackFit.expand,
              children: [
                bg,
                for (final s in _stickers)
                  _buildStickerOverlay(
                    theme: theme,
                    sticker: s,
                    canvasWidth: w,
                    canvasHeight: h,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCanvasBackground(ThemeData theme) {
    final text = _textController.text.trim();

    if (_type == _StoryType.gif && (_gifUrl ?? '').trim().isNotEmpty) {
      return SafeNetworkImage(
        url: _gifUrl,
        fit: BoxFit.cover,
      );
    }

    if (_type == _StoryType.image || _type == _StoryType.video) {
      if (_selectedMedia == null) {
        return Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Center(
            child: Text(
              'No media selected',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        );
      }

      final isImage = _type == _StoryType.image;
      if (isImage) {
        return FutureBuilder<Uint8List>(
          future: _selectedMedia!.readAsBytes(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            return Image.memory(
              snap.data!,
              fit: BoxFit.cover,
            );
          },
        );
      }

      return Container(
        color: Colors.black12,
        child: const Center(
          child: Icon(IOSIcons.videoCam, size: 42),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            text.isEmpty ? 'Your story' : text,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickerOverlay({
    required ThemeData theme,
    required StorySticker sticker,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    const stickerWidth = 190.0;
    const stickerHeight = 56.0;

    final left = (sticker.posX * canvasWidth) - (stickerWidth / 2);
    final top = (sticker.posY * canvasHeight) - (stickerHeight / 2);

    String title = sticker.type;
    try {
      if ((sticker.dataJson ?? '').trim().isNotEmpty) {
        final data = jsonDecode(sticker.dataJson!) as Map<String, dynamic>;
        if (sticker.type == 'poll') {
          title = (data['question'] as String?) ?? 'Poll';
        } else if (sticker.type == 'question') {
          title = (data['prompt'] as String?) ?? 'Question';
        } else if (sticker.type == 'emoji_slider') {
          final emoji = (data['emoji'] as String?) ?? '🔥';
          final label = (data['label'] as String?) ?? '';
          title = label.trim().isEmpty ? emoji : '$emoji  $label';
        }
      }
    } catch (_) {
      // swallow
    }

    final child = Container(
      width: stickerWidth,
      height: stickerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            sticker.type == 'poll'
                ? Icons.poll_outlined
                : sticker.type == 'question'
                    ? IOSIcons.chatBubbleOutline
                    : Icons.local_fire_department_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove sticker',
            onPressed: _submitting
                ? null
                : () async {
                    setState(() {
                      _stickers.removeWhere((e) => e.id == sticker.id);
                    });
                    await _saveDraft();
                  },
            icon: const Icon(IOSIcons.close, size: 16),
          ),
        ],
      ),
    );

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: _submitting
            ? null
            : (d) {
                final dx = d.delta.dx / canvasWidth;
                final dy = d.delta.dy / canvasHeight;
                setState(() {
                  final idx = _stickers.indexWhere((e) => e.id == sticker.id);
                  if (idx < 0) return;
                  final cur = _stickers[idx];
                  _stickers[idx] = StorySticker(
                    id: cur.id,
                    type: cur.type,
                    posX: (cur.posX + dx).clamp(0.05, 0.95),
                    posY: (cur.posY + dy).clamp(0.06, 0.94),
                    dataJson: cur.dataJson,
                    pollCounts: cur.pollCounts,
                    myPollChoice: cur.myPollChoice,
                    questionAnswerCount: cur.questionAnswerCount,
                    myQuestionAnswer: cur.myQuestionAnswer,
                    emojiSliderAvg: cur.emojiSliderAvg,
                    emojiSliderCount: cur.emojiSliderCount,
                    myEmojiSliderValue: cur.myEmojiSliderValue,
                  );
                });
              },
        onPanEnd: _submitting
            ? null
            : (_) {
                _saveDraft();
              },
        child: child,
      ),
    );
  }

  Widget _buildTypeChip(ThemeData theme, _StoryType type, String label) {
    final selected = _type == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _type = type;
        });
        _saveDraft();
      },
      selectedColor: theme.colorScheme.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color:
            selected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
      ),
    );
  }
}
