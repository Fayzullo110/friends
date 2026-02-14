import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/post_service.dart';

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
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
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

                      final username = user.email?.split('@').first ?? 'user';

                      if (_type == _PostType.thought) {
                        await PostService.instance.createTextPost(
                          authorId: user.uid,
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

                        final file = File(_selectedMedia!.path);
                        final storage = FirebaseStorage.instance;
                        final ext = _selectedMedia!.path.split('.').last;
                        final isVideo = _type == _PostType.video;
                        final ref = storage
                            .ref()
                            .child('posts/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$ext');

                        await ref.putFile(file);
                        final url = await ref.getDownloadURL();

                        await PostService.instance.createMediaPost(
                          authorId: user.uid,
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

class _MediaPlaceholder extends StatelessWidget {
  final _PostType type;
  final XFile? file;
  final VoidCallback onPick;

  const _MediaPlaceholder({
    required this.type,
    required this.file,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isImage = type == _PostType.image;
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
          if (file != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: isImage ? 4 / 3 : 9 / 16,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(file!.path),
                      fit: BoxFit.cover,
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
                            Icons.play_arrow_rounded,
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
            onPressed: onPick,
            icon: const Icon(Icons.folder_open),
            label: Text(isImage ? 'Choose image' : 'Choose video'),
          ),
        ],
      ),
    );
  }
}
