import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';

import '../../services/story_service.dart';
import '../../services/auth_service.dart';
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

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
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
            if (_type == _StoryType.image || _type == _StoryType.video)
              _buildMediaPreview(theme)
            else if (_type == _StoryType.gif)
              _buildGifPreview(theme)
            else
              const SizedBox.shrink(),
            const SizedBox(height: 12),
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

  Widget _buildTypeChip(ThemeData theme, _StoryType type, String label) {
    final selected = _type == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _type = type;
        });
      },
      selectedColor: theme.colorScheme.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color:
            selected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
      ),
    );
  }

  Widget _buildMediaPreview(ThemeData theme) {
    if (_selectedMedia == null) {
      return Text(
        'No media selected',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      );
    }

    final isImage = _type == _StoryType.image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: isImage ? 9 / 16 : 9 / 16,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isImage)
              FutureBuilder<Uint8List>(
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
              )
            else
              Container(
                color: Colors.black12,
                child: const Center(
                  child: Icon(IOSIcons.videoCam, size: 42),
                ),
              ),
            if (!isImage)
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    IOSIcons.play,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGifPreview(ThemeData theme) {
    if (_gifUrl == null || _gifUrl!.isEmpty) {
      return Text(
        'No GIF selected',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: SafeNetworkImage(
          url: _gifUrl,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
