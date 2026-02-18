import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/chat_message.dart';
import '../../models/app_user.dart';
import '../../services/chat_service.dart';
import '../../services/video_call_service.dart';
import '../../services/auth_service.dart';
import '../../theme/ios_icons.dart';
import 'jitsi_call_screen.dart';
import 'media_actions_sheet.dart';
import 'video_player_screen.dart';
import 'voice_message_player.dart';

enum RecordMode {
  voice,
  video,
}

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final String? otherUserId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.title,
    this.otherUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final AudioRecorder _voiceRecorder = AudioRecorder();
  bool _isRecording = false;
  RecordMode _recordMode = RecordMode.voice;
  bool _isTyping = false;
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    _voiceRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentUserId = AuthService.instance.currentUser?.id;
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('Please log in to chat.')),
      );
    }

    final isDark = theme.brightness == Brightness.dark;
    final lightChatBg = const Color(0xFFF3EEFF);
    final appBarBg = isDark ? theme.appBarTheme.backgroundColor : Colors.white;
    final appBarFg = isDark ? theme.appBarTheme.foregroundColor : Colors.black;

    final String? directOtherId = widget.otherUserId;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : lightChatBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: isDark ? 1 : 0,
        titleSpacing: 12,
        title: Row(
          children: [
            if (directOtherId == null)
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                child: Text(
                  widget.title.isNotEmpty
                      ? widget.title.substring(0, 1).toUpperCase()
                      : 'C',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              FutureBuilder<AppUser>(
                future: AuthService.instance.api.getJson(
                  '/api/users/$directOtherId',
                  (json) => AppUser.fromJson(json),
                ),
                builder: (context, snap) {
                  final u = snap.data;
                  final photoUrl = u?.photoUrl;
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.12),
                    foregroundImage:
                        (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                    child: Text(
                      widget.title.isNotEmpty
                          ? widget.title.substring(0, 1).toUpperCase()
                          : 'C',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(width: 10),
            Expanded(
              child: StreamBuilder<Map<String, bool>>(
                stream: ChatService.instance.watchTyping(chatId: widget.chatId),
                builder: (context, snap) {
                  final typingMap = snap.data ?? const <String, bool>{};
                  final isTyping = typingMap.isNotEmpty;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isTyping)
                        Text(
                          'Typing…',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                if (kIsWeb) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => JitsiCallScreen(
                        roomName: 'friends_chat_${widget.chatId}',
                        title: widget.title,
                      ),
                    ),
                  );
                } else {
                  await VideoCallService.instance.joinChatCall(
                    chatId: widget.chatId,
                    title: widget.title,
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            icon: const Icon(IOSIcons.phone),
            tooltip: 'Call',
          ),
          IconButton(
            onPressed: () async {
              try {
                if (kIsWeb) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => JitsiCallScreen(
                        roomName: 'friends_chat_${widget.chatId}',
                        title: widget.title,
                      ),
                    ),
                  );
                } else {
                  await VideoCallService.instance.joinChatCall(
                    chatId: widget.chatId,
                    title: widget.title,
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            icon: const Icon(IOSIcons.videoCam),
            tooltip: 'Video call',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(IOSIcons.moreVert),
            tooltip: 'More',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream:
                  ChatService.instance.watchMessages(chatId: widget.chatId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  );
                }

                // Mark messages from others as seen when they are loaded.
                final unreadForMe = messages.where((m) =>
                    m.senderId != currentUserId &&
                    !m.seenBy.contains(currentUserId));
                if (unreadForMe.isNotEmpty) {
                  ChatService.instance.markMessagesSeen(
                    chatId: widget.chatId,
                    messageIds:
                        unreadForMe.map((m) => m.id).toList(),
                    userId: currentUserId,
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isMe = m.senderId == currentUserId;
                    return _ChatBubble(
                      message: m,
                      isMe: isMe,
                      chatId: widget.chatId,
                      currentUserId: currentUserId,
                      onLongPress: () {
                        _showReactionsBar(m.id, currentUserId);
                      },
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) =>
                              MediaActionsSheet(chatId: widget.chatId),
                        );
                      },
                      icon: const Icon(IOSIcons.addCircleOutline),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(currentUserId),
                        onChanged: (value) {
                          final trimmed = value.trim();
                          final isNowTyping = trimmed.isNotEmpty;
                          if (isNowTyping != _isTyping) {
                            ChatService.instance.setTyping(
                              chatId: widget.chatId,
                              userId: currentUserId,
                              isTyping: isNowTyping,
                            );
                          }
                          if (isNowTyping != _hasText) {
                            setState(() {
                              _isTyping = isNowTyping;
                              _hasText = isNowTyping;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'Type your message…',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (!_hasText) ...[
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _recordMode = _recordMode == RecordMode.voice
                                ? RecordMode.video
                                : RecordMode.voice;
                          });
                        },
                        onLongPress: () {
                          if (_recordMode == RecordMode.voice) {
                            _toggleVoiceRecord(currentUserId);
                          } else {
                            _startVideoCapture(currentUserId);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _recordMode == RecordMode.video
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.12)
                                : (_isRecording
                                    ? Colors.redAccent.withOpacity(0.15)
                                    : Colors.transparent),
                          ),
                          child: Icon(
                            _recordMode == RecordMode.voice
                                ? (_isRecording ? IOSIcons.stop : IOSIcons.mic)
                                : IOSIcons.videoCam,
                            color: _recordMode == RecordMode.video
                                ? Theme.of(context).colorScheme.primary
                                : (_isRecording
                                    ? Colors.redAccent
                                    : Theme.of(context).iconTheme.color),
                          ),
                        ),
                      ),
                    ],
                    if (_hasText) ...[
                      const SizedBox(width: 6),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary,
                        ),
                        child: IconButton(
                          onPressed: () => _send(currentUserId),
                          icon: const Icon(
                            IOSIcons.send,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(String currentUserId) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    _controller.clear();

    if (_isTyping || _hasText) {
      setState(() {
        _isTyping = false;
        _hasText = false;
      });
      ChatService.instance.setTyping(
        chatId: widget.chatId,
        userId: currentUserId,
        isTyping: false,
      );
    }

    try {
      await ChatService.instance.sendText(
        chatId: widget.chatId,
        senderId: currentUserId,
        text: text,
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message.')),
      );
    }
  }

  Future<void> _toggleVoiceRecord(String currentUserId) async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice recording is only available on mobile devices.'),
        ),
      );
      return;
    }

    try {
      if (!_isRecording) {
        final hasPermission = await _voiceRecorder.hasPermission();
        if (!hasPermission) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied.')),
          );
          return;
        }

        final dir = await getTemporaryDirectory();
        final filePath =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _voiceRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );
        if (!mounted) return;
        setState(() {
          _isRecording = true;
        });
      } else {
        final path = await _voiceRecorder.stop();
        if (!mounted) return;
        setState(() {
          _isRecording = false;
        });

        if (path == null) return;

        final bytes = await XFile(path).readAsBytes();
        final fileName =
            'voice_${DateTime.now().millisecondsSinceEpoch.toString()}.m4a';

        // TODO: Replace with backend file upload
        // final storageRef = FirebaseStorage.instance
        //     .ref()
        //     .child('chatMedia')
        //     .child(widget.chatId)
        //     .child(fileName);
        // await storageRef.putData(bytes);
        // final url = await storageRef.getDownloadURL();
        final upload = await AuthService.instance.api.uploadFile(
          path: '/api/uploads',
          bytes: bytes,
          filename: fileName,
        );
        final url = (upload['url'] as String?) ?? '';
        if (url.isEmpty) throw Exception('Upload failed');

        await ChatService.instance.sendVoice(
          chatId: widget.chatId,
          senderId: currentUserId,
          audioUrl: url,
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record voice message.')),
      );
    }
  }

  Future<void> _startVideoCapture(String currentUserId) async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Video recording is only available on mobile devices.'),
        ),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickVideo(source: ImageSource.camera);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      // TODO: Replace with backend file upload
      // final storageRef = FirebaseStorage.instance
      //     .ref()
      //     .child('chatMedia')
      //     .child(widget.chatId)
      //     .child('video_${DateTime.now().millisecondsSinceEpoch}.mp4');

      // final task = await storageRef.putData(bytes);
      // final url = await task.ref.getDownloadURL();
      final upload = await AuthService.instance.api.uploadFile(
        path: '/api/uploads',
        bytes: bytes,
        filename: 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      final url = (upload['url'] as String?) ?? '';
      if (url.isEmpty) throw Exception('Upload failed');

      await ChatService.instance.sendVideo(
        chatId: widget.chatId,
        senderId: currentUserId,
        videoUrl: url,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record video message.')),
      );
    }
  }

  void _showReactionsBar(String messageId, String currentUserId) {
    final controller = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
              left: 16,
              right: 16,
            ),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Choose emoji',
                        ),
                        onSubmitted: (value) async {
                          final emoji = value.trim();
                          if (emoji.isEmpty) {
                            Navigator.of(ctx).pop();
                            return;
                          }
                          Navigator.of(ctx).pop();
                          await ChatService.instance.toggleReaction(
                            chatId: widget.chatId,
                            messageId: messageId,
                            userId: currentUserId,
                            emoji: emoji,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(IOSIcons.checkCircleOutlined),
                      color: theme.colorScheme.primary,
                      onPressed: () async {
                        final emoji = controller.text.trim();
                        if (emoji.isEmpty) {
                          Navigator.of(ctx).pop();
                          return;
                        }
                        Navigator.of(ctx).pop();
                        await ChatService.instance.toggleReaction(
                          chatId: widget.chatId,
                          messageId: messageId,
                          userId: currentUserId,
                          emoji: emoji,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      // ignore
    });

    // Note: no state to reset here.
  }

}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String chatId;
  final String currentUserId;
  final VoidCallback? onLongPress;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.chatId,
    required this.currentUserId,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final isDark = theme.brightness == Brightness.dark;

    final bubbleColor = isMe
        ? (isDark
            ? theme.colorScheme.primary
            : const Color(0xFF7B61FF))
        : (isDark ? theme.colorScheme.surface : Colors.white);

    final textColor = isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    final onSurface = theme.colorScheme.onSurface;

    final anyOtherSeen =
        message.seenBy.any((uid) => uid != currentUserId);
    final statusText = isMe
        ? (anyOtherSeen ? '✓✓' : '✓')
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: _buildContent(context, textColor),
            ),
          ),
          const SizedBox(height: 4),
          if (message.reactions.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 2,
              alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
              children: [
                for (final entry in message.reactions.entries)
                  _ReactionChip(
                    emoji: entry.key,
                    count: entry.value.length,
                    isMine: entry.value.contains(currentUserId),
                    isMe: isMe,
                    onSurface: onSurface,
                    primary: theme.colorScheme.primary,
                  ),
              ],
            ),
          if (message.reactions.isNotEmpty) const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: anyOtherSeen
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface
                            .withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildContent(BuildContext context, Color textColor) {
    switch (message.type) {
      case ChatMessageType.gif:
        if (message.mediaUrl == null || message.mediaUrl!.isEmpty) {
          return const Text('GIF');
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: message.mediaUrl!,
            fit: BoxFit.cover,
          ),
        );
      case ChatMessageType.image:
        if (message.mediaUrl == null || message.mediaUrl!.isEmpty) {
          return const Text('Image');
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: message.mediaUrl!,
            fit: BoxFit.cover,
          ),
        );
      case ChatMessageType.video:
        if (message.mediaUrl == null || message.mediaUrl!.isEmpty) {
          return const Text('Video');
        }
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VideoPlayerScreen(url: message.mediaUrl!),
              ),
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: message.mediaUrl!,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  IOSIcons.play,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        );
      case ChatMessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(IOSIcons.document, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'File',
                style: TextStyle(
                  color: textColor,
                  height: 1.25,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case ChatMessageType.voice:
        if (message.mediaUrl == null || message.mediaUrl!.isEmpty) {
          return const Text('Voice message');
        }
        return VoiceMessagePlayer(url: message.mediaUrl!);
      case ChatMessageType.text:
        return Text(
          message.text ?? '',
          style: TextStyle(
            color: textColor,
            height: 1.25,
          ),
        );
    }
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool isMine;
  final bool isMe;
  final Color onSurface;
  final Color primary;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.isMine,
    required this.isMe,
    required this.onSurface,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMine
        ? primary.withOpacity(0.15)
        : onSurface.withOpacity(0.06);
    final textColor = isMine ? primary : onSurface.withOpacity(0.8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 2),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 11, color: textColor),
          ),
        ],
      ),
    );
  }
}
