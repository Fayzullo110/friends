import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/post_service.dart';
import '../../services/auth_service.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CreatePostScaffold();
  }
}

enum _PostType { thought, image, video }

class _CreatePostScaffold extends StatefulWidget {
  const _CreatePostScaffold();

  @override
  State<_CreatePostScaffold> createState() => _CreatePostScaffoldState();
}

class _CreatePostScaffoldState extends State<_CreatePostScaffold> {
  _PostType _type = _PostType.thought;
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedMedia;
  bool _submitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create'),
        actions: [
          TextButton(
            onPressed: _submitting
                ? null
                : () async {
                    final text = _textController.text.trim();
                    if (text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Write something first.')),
                      );
                      return;
                    }

                    try {
                      final me = AuthService.instance.currentUser;
                      if (me == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Session expired. Please log in again to share.'),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        _submitting = true;
                      });

                      final username = me.username;

                      if (_type == _PostType.thought) {
                        await PostService.instance.createTextPost(
                          authorId: me.id,
                          authorUsername: username,
                          text: text,
                        );
                      } else {
                        if (_selectedMedia == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please select an image or video to share.'),
                            ),
                          );
                          return;
                        }

                        final bytes = await _selectedMedia!.readAsBytes();
                        final upload = await AuthService.instance.api.uploadFile(
                          path: '/api/uploads',
                          bytes: bytes,
                          filename: _selectedMedia!.name,
                        );
                        final url = (upload['url'] as String?) ?? '';
                        if (url.isEmpty) throw Exception('Upload failed');

                        final isVideo = _type == _PostType.video;
                        // final ref = storage
                        //     .ref()
                        //     .child('posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$ext');

                        // await ref.putFile(file);
                        // final url = await ref.getDownloadURL();

                        await PostService.instance.createMediaPost(
                          authorId: me.id,
                          authorUsername: username,
                          text: text,
                          mediaUrl: url,
                          mediaType: isVideo ? 'video' : 'image',
                        );
                      }

                      _textController.clear();
                      _selectedMedia = null;
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Posted your moment.')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to post. Please try again.'),
                        ),
                      );
                    } finally {
                      if (mounted) {
                        setState(() {
                          _submitting = false;
                        });
                      }
                    }
                  },
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
            const Text(
              'What do you want to share?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildTypeChip(theme, _PostType.thought, 'Thought'),
                _buildTypeChip(theme, _PostType.image, 'Image moment'),
                _buildTypeChip(theme, _PostType.video, 'Video reel'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _textController,
                      maxLines: 4,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: _type == _PostType.thought
                            ? "Share what's on your mind..."
                            : 'Write a caption for your Friends...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant
                            .withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_type != _PostType.thought)
                      _MediaPlaceholder(
                        type: _type,
                        file: _selectedMedia,
                        onPick: () async {
                          final source = ImageSource.gallery;
                          final picked = _type == _PostType.image
                              ? await _picker.pickImage(source: source)
                              : await _picker.pickVideo(source: source);
                          if (picked == null) return;
                          setState(() {
                            _selectedMedia = picked;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(ThemeData theme, _PostType type, String label) {
    final isSelected = _type == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _type = type;
        });
      },
      selectedColor: theme.colorScheme.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.textTheme.bodyMedium?.color,
      ),
    );
  }
}

class _MediaPlaceholder extends StatefulWidget {
  final _PostType type;
  final XFile? file;
  final VoidCallback onPick;

  const _MediaPlaceholder({
    required this.type,
    required this.file,
    required this.onPick,
  });

  @override
  State<_MediaPlaceholder> createState() => _MediaPlaceholderState();
}

class _MediaPlaceholderState extends State<_MediaPlaceholder> {
  String? _bytesForPath;
  Future<Uint8List>? _bytesFuture;

  @override
  void didUpdateWidget(covariant _MediaPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextPath = widget.file?.path;
    if (_bytesForPath != null && nextPath != _bytesForPath) {
      _bytesForPath = null;
      _bytesFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isImage = widget.type == _PostType.image;
    final icon = isImage
        ? PhosphorIconsLight.image
        : PhosphorIconsLight.playCircle;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.file != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: isImage ? 1 : 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (isImage)
                      FutureBuilder<Uint8List>(
                        future: () {
                          final path = widget.file!.path;
                          if (_bytesForPath != path || _bytesFuture == null) {
                            _bytesForPath = path;
                            _bytesFuture = widget.file!.readAsBytes();
                          }
                          return _bytesFuture;
                        }(),
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
                          child: Icon(Icons.videocam_outlined, size: 42),
                        ),
                      ),
                    if (!isImage)
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(height: 8),
                Text(
                  isImage
                      ? 'Pick an image to share as a moment.'
                      : 'Pick a video to share as a reel.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.onPick,
            icon: const Icon(Icons.folder_open),
            label: Text(isImage ? 'Choose image' : 'Choose video'),
          ),
        ],
      ),
    );
  }
}
