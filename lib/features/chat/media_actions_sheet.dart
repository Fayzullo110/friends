import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import 'gif_picker_sheet.dart';

class MediaActionsSheet extends StatefulWidget {
  final String chatId;
  final String? replyToMessageId;

  const MediaActionsSheet({
    super.key,
    required this.chatId,
    this.replyToMessageId,
  });

  @override
  State<MediaActionsSheet> createState() => _MediaActionsSheetState();
}

class _MediaActionsSheetState extends State<MediaActionsSheet> {
  bool _isSending = false;
  String? _sendingLabel;
  int? _uploadSentBytes;
  int? _uploadTotalBytes;

  Future<void> _runSend(String label, Future<void> Function() fn) async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _sendingLabel = label;
      _uploadSentBytes = null;
      _uploadTotalBytes = null;
    });
    try {
      await fn();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty ? 'Failed to send media.' : message,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendingLabel = null;
          _uploadSentBytes = null;
          _uploadTotalBytes = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final sent = _uploadSentBytes;
    final total = _uploadTotalBytes;
    final progress = (sent != null && total != null && total > 0)
        ? (sent / total).clamp(0.0, 1.0)
        : null;

    final title = _isSending
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _sendingLabel ?? 'Sending…',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(value: progress),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(progress * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          )
        : Text(
            'Add to message',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: 12),
            AbsorbPointer(
              absorbing: _isSending,
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _ActionChip(
                    icon: Icons.photo,
                    label: 'Photo',
                    onTap: () => _pickPhoto(),
                    enabled: !_isSending,
                  ),
                  _ActionChip(
                    icon: Icons.videocam_outlined,
                    label: 'Video',
                    onTap: () => _pickVideo(),
                    enabled: !_isSending,
                  ),
                  _ActionChip(
                    icon: Icons.insert_drive_file_outlined,
                    label: 'File',
                    onTap: () => _pickFile(),
                    enabled: !_isSending,
                  ),
                  _ActionChip(
                    icon: Icons.mic_none,
                    label: 'Audio / Voice',
                    onTap: () => _pickAudio(),
                    enabled: !_isSending,
                  ),
                  _ActionChip(
                    icon: Icons.gif_box_outlined,
                    label: 'GIF',
                    enabled: !_isSending,
                    onTap: () async {
                      if (_isSending) return;
                      Navigator.of(context).pop();
                      final me = AuthService.instance.currentUser;
                      if (me == null) return;

                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) {
                          return SizedBox(
                            height: MediaQuery.of(ctx).size.height * 0.6,
                            child: GifPickerSheet(
                              onSelected: (gif) async {
                                await ChatService.instance.sendGif(
                                  chatId: widget.chatId,
                                  senderId: me.id,
                                  gifUrl: gif.originalUrl,
                                  replyToMessageId: widget.replyToMessageId,
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    await _runSend('Sending photo…', () async {
      final picker = ImagePicker();
      final me = AuthService.instance.currentUser;
      if (me == null) return;

      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final downloadUrl = await _uploadBytes(
        bytes: bytes,
        fileName: picked.name,
      );
      if (downloadUrl.trim().isEmpty) {
        throw Exception('Upload failed');
      }

      await ChatService.instance.sendImage(
        chatId: widget.chatId,
        senderId: me.id,
        imageUrl: downloadUrl,
        replyToMessageId: widget.replyToMessageId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  Future<void> _pickVideo() async {
    await _runSend('Sending video…', () async {
      final picker = ImagePicker();
      final me = AuthService.instance.currentUser;
      if (me == null) return;

      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final downloadUrl = await _uploadBytes(
        bytes: bytes,
        fileName: picked.name,
      );
      if (downloadUrl.trim().isEmpty) {
        throw Exception('Upload failed');
      }

      await ChatService.instance.sendVideo(
        chatId: widget.chatId,
        senderId: me.id,
        videoUrl: downloadUrl,
        replyToMessageId: widget.replyToMessageId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  Future<void> _pickFile() async {
    await _runSend('Sending file…', () async {
      final me = AuthService.instance.currentUser;
      if (me == null) return;

      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) return;

      final downloadUrl = await _uploadBytes(
        bytes: bytes,
        fileName: file.name,
      );
      if (downloadUrl.trim().isEmpty) {
        throw Exception('Upload failed');
      }

      await ChatService.instance.sendFile(
        chatId: widget.chatId,
        senderId: me.id,
        fileUrl: downloadUrl,
        replyToMessageId: widget.replyToMessageId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  Future<void> _pickAudio() async {
    await _runSend('Sending audio…', () async {
      final me = AuthService.instance.currentUser;
      if (me == null) return;

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
      if (downloadUrl.trim().isEmpty) {
        throw Exception('Upload failed');
      }

      await ChatService.instance.sendVoice(
        chatId: widget.chatId,
        senderId: me.id,
        audioUrl: downloadUrl,
        replyToMessageId: widget.replyToMessageId,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    });
  }

  Future<String> _uploadBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final upload = await AuthService.instance.api.uploadFile(
      path: '/api/uploads',
      bytes: bytes,
      filename: fileName,
      onProgress: (sentBytes, totalBytes) {
        if (!mounted) return;
        setState(() {
          _uploadSentBytes = sentBytes;
          _uploadTotalBytes = totalBytes;
        });
      },
    );
    return (upload['url'] as String?) ?? '';
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surfaceVariant.withOpacity(enabled ? 0.5 : 0.25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: enabled
                  ? null
                  : theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: enabled
                    ? null
                    : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
