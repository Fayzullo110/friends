import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/chat_message.dart';
import '../../models/story.dart';
import '../../services/chat_service.dart';
import '../../services/video_call_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_cache_service.dart';
import '../../services/story_service.dart';
import '../../theme/ios_icons.dart';
import '../../theme/app_themes.dart';
import '../../widgets/safe_network_image.dart';
import '../story/story_viewer_screen.dart';
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
  final ScrollController _messagesScrollController = ScrollController();
  bool _isRecording = false;
  RecordMode _recordMode = RecordMode.voice;
  bool _isTyping = false;
  bool _hasText = false;
  bool _isSending = false;

  late final StreamSubscription<String> _userCacheSub;

  static const int _pageSize = 50;
  int _olderOffset = _pageSize;
  bool _isLoadingOlder = false;
  bool _hasMoreOlder = true;
  final List<ChatMessage> _olderMessages = <ChatMessage>[];
  final Set<String> _seenMessageIds = <String>{};

  @override
  void dispose() {
    _controller.dispose();
    _voiceRecorder.dispose();
    _messagesScrollController.dispose();
    _userCacheSub.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _messagesScrollController.addListener(_maybeLoadOlder);
    _userCacheSub = UserCacheService.instance.updates.listen((_) {
      if (mounted) setState(() {});
    });
  }

  void _maybeLoadOlder() {
    if (_isLoadingOlder || !_hasMoreOlder) return;
    final pos = _messagesScrollController.position;
    if (!pos.hasPixels || !pos.hasContentDimensions) return;

    // ListView is reverse:true. When you scroll up to older messages, the
    // scroll offset approaches maxScrollExtent.
    if (pos.pixels >= (pos.maxScrollExtent - 300)) {
      _loadOlder();
    }
  }

  Future<void> _loadOlder() async {
    if (_isLoadingOlder || !_hasMoreOlder) return;

    final double? beforeMaxExtent = _messagesScrollController.hasClients
        ? _messagesScrollController.position.maxScrollExtent
        : null;
    final double? beforePixels = _messagesScrollController.hasClients
        ? _messagesScrollController.position.pixels
        : null;

    setState(() {
      _isLoadingOlder = true;
    });

    try {
      final next = await ChatService.instance.fetchMessagesPage(
        chatId: widget.chatId,
        limit: _pageSize,
        offset: _olderOffset,
      );

      if (!mounted) return;

      final List<ChatMessage> accepted = <ChatMessage>[];
      for (final m in next) {
        if (_seenMessageIds.contains(m.id)) continue;
        _seenMessageIds.add(m.id);
        accepted.add(m);
      }

      setState(() {
        _olderMessages.addAll(accepted);
        _olderOffset += _pageSize;
        if (next.length < _pageSize) {
          _hasMoreOlder = false;
        }
      });

      if (_messagesScrollController.hasClients &&
          beforeMaxExtent != null &&
          beforePixels != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_messagesScrollController.hasClients) return;
          final afterMax = _messagesScrollController.position.maxScrollExtent;
          final delta = afterMax - beforeMaxExtent;
          if (delta.abs() < 0.5) return;
          final nextPixels = beforePixels + delta;
          _messagesScrollController.jumpTo(
            nextPixels.clamp(
              _messagesScrollController.position.minScrollExtent,
              _messagesScrollController.position.maxScrollExtent,
            ),
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasMoreOlder = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOlder = false;
        });
      }
    }
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
    if (directOtherId != null) {
      UserCacheService.instance.get(directOtherId);
    }

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
              StreamBuilder<List<Story>>(
                stream:
                    StoryService.instance.watchUserStories(authorId: directOtherId),
                builder: (context, storySnap) {
                  final stories = storySnap.data ?? const <Story>[];
                  final hasStory = stories.isNotEmpty;
                  final allSeen = hasStory
                      ? stories.every((s) => s.seenBy.contains(currentUserId))
                      : false;

                  final u = UserCacheService.instance.peek(directOtherId);
                  final photoUrl = u?.photoUrl;
                  final accent = AppThemes.seedFor(
                    themeKey: u?.themeKey,
                    themeSeedColor: u?.themeSeedColor,
                  );

                  final avatar = CircleAvatar(
                    radius: 18,
                    backgroundColor: accent.withOpacity(0.12),
                    child: ClipOval(
                      child: (photoUrl != null && photoUrl.trim().isNotEmpty)
                          ? SafeNetworkImage(
                              url: photoUrl,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                widget.title.isNotEmpty
                                    ? widget.title.substring(0, 1).toUpperCase()
                                    : 'C',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  );

                  final decorated = hasStory
                      ? Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: allSeen
                                  ? <Color>[
                                      theme.colorScheme.onSurface
                                          .withOpacity(0.25),
                                      theme.colorScheme.onSurface
                                          .withOpacity(0.10),
                                    ]
                                  : <Color>[
                                      accent.withOpacity(0.85),
                                      accent.withOpacity(0.45),
                                    ],
                            ),
                          ),
                          child: avatar,
                        )
                      : avatar;

                  return GestureDetector(
                    onTap: hasStory
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StoryViewerScreen(
                                  stories: List<Story>.from(stories),
                                ),
                              ),
                            );
                          }
                        : null,
                    child: decorated,
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
                  ChatService.instance.watchMessages(
                chatId: widget.chatId,
                limit: _pageSize,
                offset: 0,
              ),
              builder: (context, snapshot) {
                final live = snapshot.data ?? const <ChatMessage>[];

                // Maintain a global seen-set to avoid duplicates when merging.
                for (final m in live) {
                  _seenMessageIds.add(m.id);
                }

                final List<ChatMessage> messages = <ChatMessage>[
                  ...live,
                  ..._olderMessages,
                ];
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
                  controller: _messagesScrollController,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index >= messages.length) {
                      if (_isLoadingOlder) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      if (!_hasMoreOlder) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'No more messages',
                              style: TextStyle(color: Colors.black45),
                            ),
                          ),
                        );
                      }

                      // A stable top-of-history indicator. Auto-load is driven
                      // by the scroll listener; this provides a manual fallback.
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: TextButton(
                            onPressed: _loadOlder,
                            child: const Text('Load older messages'),
                          ),
                        ),
                      );
                    }

                    final m = messages[index];
                    final isMe = m.senderId == currentUserId;

                    return _ChatBubble(
                      message: m,
                      isMe: isMe,
                      chatId: widget.chatId,
                      currentUserId: currentUserId,
                      senderPhotoUrl: isMe ? null : m.senderPhotoUrl,
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
                      onPressed: _isSending
                          ? null
                          : () {
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
                        enabled: !_isSending,
                        onSubmitted: _isSending ? null : (_) => _send(currentUserId),
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
                        onTap: _isSending
                            ? null
                            : () {
                          setState(() {
                            _recordMode = _recordMode == RecordMode.voice
                                ? RecordMode.video
                                : RecordMode.voice;
                          });
                        },
                        onLongPress: _isSending
                            ? null
                            : () {
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
                          onPressed: _isSending ? null : () => _send(currentUserId),
                          icon: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(
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

  Future<void> _runSend(Future<void> Function() work) async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
    });
    try {
      await work();
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
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

    await _runSend(() async {
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
    });
  }

  Future<void> _toggleVoiceRecord(String currentUserId) async {
    if (_isSending) return;
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
        await _runSend(() async {
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
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record voice message.')),
      );
    }
  }

  Future<void> _startVideoCapture(String currentUserId) async {
    if (_isSending) return;
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
      await _runSend(() async {
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
      });
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
  final String? senderPhotoUrl;
  final VoidCallback? onLongPress;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.chatId,
    required this.currentUserId,
    required this.senderPhotoUrl,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final isDark = theme.brightness == Brightness.dark;

    final bubbleColor = isMe
        ? (isDark ? theme.colorScheme.primary : const Color(0xFF7B61FF))
        : (isDark ? theme.colorScheme.surface : Colors.white);

    final textColor = isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final onSurface = theme.colorScheme.onSurface;

    final anyOtherSeen = message.seenBy.any((uid) => uid != currentUserId);
    final statusText = isMe ? (anyOtherSeen ? '✓✓' : '✓') : '';

    final bubble = Column(
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
                color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ],
    );

    if (isMe) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: bubble,
      );
    }

    final username = message.senderUsername;
    final initial =
        username.isNotEmpty ? username.substring(0, 1).toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: ClipOval(
              child: (senderPhotoUrl != null && senderPhotoUrl!.trim().isNotEmpty)
                  ? SafeNetworkImage(
                      url: senderPhotoUrl,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: bubble),
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
          child: SafeNetworkImage(
            url: message.mediaUrl,
            fit: BoxFit.cover,
          ),
        );
      case ChatMessageType.image:
        if (message.mediaUrl == null || message.mediaUrl!.isEmpty) {
          return const Text('Image');
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SafeNetworkImage(
            url: message.mediaUrl,
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
                child: SafeNetworkImage(
                  url: message.mediaUrl,
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
