import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/chat_service.dart';
import 'gif_picker_sheet.dart';

class MediaActionsSheet extends StatelessWidget {
  final String chatId;

  const MediaActionsSheet({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add to message',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _ActionChip(
                  icon: Icons.photo,
                  label: 'Photo',
                  onTap: () => _pickPhoto(context),
                ),
                _ActionChip(
                  icon: Icons.videocam_outlined,
                  label: 'Video',
                  onTap: () => _pickVideo(context),
                ),
                _ActionChip(
                  icon: Icons.insert_drive_file_outlined,
                  label: 'File',
                  onTap: () => _pickFile(context),
                ),
                _ActionChip(
                  icon: Icons.mic_none,
                  label: 'Audio / Voice',
                  onTap: () => _pickAudio(context),
                ),
                _ActionChip(
                  icon: Icons.gif_box_outlined,
                  label: 'GIF',
                  onTap: () async {
                    Navigator.of(context).pop();
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) return;

                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) {
                        return SizedBox(
                          height: MediaQuery.of(ctx).size.height * 0.6,
                          child: GifPickerSheet(
                            onSelected: (gif) async {
                              await ChatService.instance.sendGif(
                                chatId: chatId,
                                senderId: currentUser.uid,
                                gifUrl: gif.originalUrl,
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      final downloadUrl = await _uploadBytes(
        bytes: bytes,
        fileName: picked.name,
      );

      await ChatService.instance.sendImage(
        chatId: chatId,
        senderId: user.uid,
        imageUrl: downloadUrl,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send media.')),
      );
    }
  }

  Future<void> _pickVideo(BuildContext context) async {
    final picker = ImagePicker();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      final downloadUrl = await _uploadBytes(
        bytes: bytes,
        fileName: picked.name,
      );

      await ChatService.instance.sendVideo(
        chatId: chatId,
        senderId: user.uid,
        videoUrl: downloadUrl,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send video.')),
      );
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) return;

      final downloadUrl = await _uploadBytes(
        bytes: bytes,
        fileName: file.name,
      );

      await ChatService.instance.sendFile(
        chatId: chatId,
        senderId: user.uid,
        fileUrl: downloadUrl,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send file.')),
      );
    }
  }

  Future<void> _pickAudio(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m4a', 'aac', 'mp3', 'wav', 'ogg'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) return;

      final downloadUrl = await _uploadBytes(
        bytes: bytes,
        fileName: file.name,
      );

      await ChatService.instance.sendVoice(
        chatId: chatId,
        senderId: user.uid,
        audioUrl: downloadUrl,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send audio.')),
      );
    }
  }

  Future<String> _uploadBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('chatMedia')
        .child(chatId)
        .child(fileName);

    final task = await storageRef.putData(bytes);
    return task.ref.getDownloadURL();
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}
