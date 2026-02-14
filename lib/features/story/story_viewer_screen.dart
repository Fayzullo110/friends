import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';

import '../../models/story.dart';
import '../../models/story_comment.dart';
import '../../services/chat_service.dart';
import '../../services/story_service.dart';
import '../../theme/ios_icons.dart';
import '../chat/video_player_screen.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final PageController _controller;
  int _currentIndex = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentMusicUrl;
  bool _musicPlaying = false;
  StreamSubscription<PlayerState>? _playerStateSub;
  late final AnimationController _progressController;
  bool _wasMusicPlayingBeforeHold = false;
  bool _musicLoading = false;
  String? _musicFailedUrl;

  static const _autoAdvanceDuration = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.stories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).maybePop();
      });
      _controller = PageController(initialPage: 0);
      _progressController = AnimationController(
        vsync: this,
        duration: _autoAdvanceDuration,
      );
      return;
    }

    _currentIndex = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _controller = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: _autoAdvanceDuration,
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        if (!mounted) return;
        _goToNext();
      });
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      final playing = state.playing;
      if (!mounted) return;
      if (_musicPlaying != playing) {
        setState(() {
          _musicPlaying = playing;
        });
      }
    });
    _markSeen(_currentIndex);
    _loadMusicForIndex(_currentIndex, autoPlay: true);
    _startProgressForIndex(_currentIndex);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _audioPlayer.pause();
      _progressController.stop();
    }
  }

  Future<void> _loadMusicForIndex(int index, {required bool autoPlay}) async {
    if (index < 0 || index >= widget.stories.length) return;
    final story = widget.stories[index];
    final url = story.musicUrl;

    // Stop if story has no music.
    if (url == null || url.isEmpty) {
      await _audioPlayer.stop();
      setState(() {
        _currentMusicUrl = null;
        _musicPlaying = false;
        _musicLoading = false;
        _musicFailedUrl = null;
      });
      return;
    }

    if (_currentMusicUrl != url) {
      try {
        setState(() {
          _musicLoading = true;
          _musicFailedUrl = null;
        });
        await _audioPlayer.setUrl(url);
        _currentMusicUrl = url;
        if (mounted) {
          setState(() {
            _musicLoading = false;
          });
        }
      } catch (_) {
        // If the URL fails to load, keep UI responsive.
        await _audioPlayer.stop();
        if (!mounted) return;
        setState(() {
          _currentMusicUrl = null;
          _musicPlaying = false;
          _musicLoading = false;
          _musicFailedUrl = url;
        });
        return;
      }
    }

    if (autoPlay) {
      try {
        await _audioPlayer.play();
        setState(() {
          _musicPlaying = true;
        });
      } catch (_) {
        setState(() {
          _musicPlaying = false;
        });
      }
    }
  }

  Future<void> _toggleMusic() async {
    if (_currentMusicUrl == null || _currentMusicUrl!.isEmpty) return;
    if (_musicPlaying) {
      await _audioPlayer.pause();
      if (!mounted) return;
      setState(() {
        _musicPlaying = false;
      });
    } else {
      await _audioPlayer.play();
      if (!mounted) return;
      setState(() {
        _musicPlaying = true;
      });
    }
  }

  Future<void> _markSeen(int index) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;
    if (index < 0 || index >= widget.stories.length) return;
    final story = widget.stories[index];
    await StoryService.instance.markSeen(
      storyId: story.id,
      userId: authUser.uid,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _playerStateSub?.cancel();
    _progressController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startProgressForIndex(int index) {
    final story = widget.stories[index];
    _progressController.stop();
    _progressController.value = 0;

    // Only auto-progress / auto-advance non-video stories.
    if (story.mediaType == 'video') {
      return;
    }
    _progressController.forward(from: 0);
  }

  void _goToNext() {
    if (_currentIndex >= widget.stories.length - 1) {
      Navigator.of(context).maybePop();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _pauseForHold() {
    _progressController.stop();
    _wasMusicPlayingBeforeHold = _musicPlaying;
    _audioPlayer.pause();
  }

  void _resumeAfterHold() {
    final story = widget.stories[_currentIndex];
    if (story.mediaType != 'video' && _progressController.value < 1.0) {
      _progressController.forward();
    }
    if (_wasMusicPlayingBeforeHold) {
      _audioPlayer.play();
    }
  }

  Future<void> _toggleLike() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like stories')),
      );
      return;
    }
    final story = widget.stories[_currentIndex];
    await StoryService.instance.toggleLike(
      storyId: story.id,
      userId: authUser.uid,
    );
  }

  void _showComments() {
    _pauseForHold();
    final story = widget.stories[_currentIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StoryCommentsSheet(
        story: story,
        onClose: _resumeAfterHold,
      ),
    ).whenComplete(_resumeAfterHold);
  }

  void _showSendOptions() {
    _pauseForHold();
    final story = widget.stories[_currentIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SendStorySheet(
        story: story,
        onClose: _resumeAfterHold,
      ),
    ).whenComplete(_resumeAfterHold);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPressStart: (_) => _pauseForHold(),
              onLongPressEnd: (_) => _resumeAfterHold(),
              onTapUp: (details) {
                final width = MediaQuery.of(context).size.width;
                final dx = details.localPosition.dx;
                if (dx < width * 0.33) {
                  // Left: previous story
                  _goToPrevious();
                } else {
                  // Right: next story
                  if (_currentIndex < widget.stories.length - 1) {
                    _goToNext();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                }
              },
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.stories.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _markSeen(index);
                  _loadMusicForIndex(index, autoPlay: true);
                  _startProgressForIndex(index);
                },
                itemBuilder: (context, index) {
                  final story = widget.stories[index];
                  return _buildStoryPage(context, story);
                },
              ),
            ),
            // Top header: progress + author + time + close.
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) {
                            return Row(
                              children: List.generate(widget.stories.length, (i) {
                                final double value =
                                    i < _currentIndex ? 1.0 : (i == _currentIndex ? _progressController.value : 0.0);
                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: value.clamp(0.0, 1.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(IOSIcons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildHeaderInfo(),
                ],
              ),
            ),
            // Bottom action bar: like, comment, share.
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildActionBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final story = widget.stories[_currentIndex];
    final username = story.authorUsername.isNotEmpty
        ? story.authorUsername
        : 'Story';
    final time = _formatTimeAgo(story.createdAt);

    return Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white24,
          child: Icon(
            IOSIcons.person,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              if (story.musicTitle != null && story.musicTitle!.isNotEmpty)
                Text(
                  '♪ ${story.musicTitle!}${(story.musicArtist != null && story.musicArtist!.isNotEmpty) ? ' • ${story.musicArtist!}' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (story.musicUrl != null && story.musicUrl!.isNotEmpty)
          if (_musicLoading)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else if (_musicFailedUrl != null && _musicFailedUrl == story.musicUrl)
            IconButton(
              icon: const Icon(IOSIcons.exclamationCircle, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Music failed to load.')),
                );
              },
            )
          else
            IconButton(
              icon: Icon(
                _musicPlaying ? IOSIcons.pause : IOSIcons.play,
                color: Colors.white,
              ),
              onPressed: _toggleMusic,
            ),
      ],
    );
  }

  Widget _buildStoryPage(BuildContext context, Story story) {
    final theme = Theme.of(context);

    switch (story.mediaType) {
      case 'image':
      case 'gif':
        if (story.mediaUrl == null || story.mediaUrl!.isEmpty) {
          return _buildTextOnlyStory(context, story);
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: story.mediaUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IOSIcons.brokenImage, color: Colors.white70, size: 42),
                    SizedBox(height: 8),
                    Text(
                      'Failed to load media',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            if (story.text != null && story.text!.isNotEmpty)
              _buildCaptionOverlay(theme, story.text!),
          ],
        );
      case 'video':
        if (story.mediaUrl == null || story.mediaUrl!.isEmpty) {
          return _buildTextOnlyStory(context, story);
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black),
            Center(
              child: IconButton(
                iconSize: 64,
                color: Colors.white,
                icon: const Icon(IOSIcons.playCircle),
                onPressed: () {
                  final wasPlaying = _musicPlaying;
                  _audioPlayer.pause();
                  setState(() {
                    _musicPlaying = false;
                  });
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(url: story.mediaUrl!),
                        ),
                      )
                      .then((_) {
                    if (!mounted) return;
                    if (wasPlaying) {
                      _loadMusicForIndex(_currentIndex, autoPlay: true);
                    }
                  });
                },
              ),
            ),
            if (story.text != null && story.text!.isNotEmpty)
              _buildCaptionOverlay(theme, story.text!),
          ],
        );
      case 'text':
      default:
        return _buildTextOnlyStory(context, story);
    }
  }

  Widget _buildTextOnlyStory(BuildContext context, Story story) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111827), Color(0xFF020617)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            story.text ?? '',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptionOverlay(ThemeData theme, String text) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Colors.black54,
                offset: Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    final story = widget.stories[_currentIndex];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = currentUserId != null && story.likedBy.contains(currentUserId);

    return Row(
      children: [
        // Like button with count
        GestureDetector(
          onTap: _toggleLike,
          child: Row(
            children: [
              Icon(
                isLiked ? IOSIcons.heartFill : IOSIcons.heart,
                color: isLiked ? Colors.redAccent : Colors.white,
                size: 28,
              ),
              const SizedBox(width: 6),
              Text(
                '${story.likedBy.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Comment button
        GestureDetector(
          onTap: _showComments,
          child: const Icon(
            IOSIcons.chatBubbleOutline,
            color: Colors.white,
            size: 26,
          ),
        ),
        const Spacer(),
        // Send/Share button
        GestureDetector(
          onTap: _showSendOptions,
          child: const Icon(
            IOSIcons.shareUp,
            color: Colors.white,
            size: 26,
          ),
        ),
      ],
    );
  }
}

class _StoryCommentsSheet extends StatefulWidget {
  final Story story;
  final VoidCallback onClose;

  const _StoryCommentsSheet({
    required this.story,
    required this.onClose,
  });

  @override
  State<_StoryCommentsSheet> createState() => _StoryCommentsSheetState();
}

class _StoryCommentsSheetState extends State<_StoryCommentsSheet> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String username = user.email?.split('@').first ?? 'user';
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = snap.data();
      final fromProfile = data?['username'] as String?;
      if (fromProfile != null && fromProfile.isNotEmpty) {
        username = fromProfile;
      }

      await StoryService.instance.addComment(
        storyId: widget.story.id,
        authorId: user.uid,
        authorUsername: username,
        text: text,
      );

      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add comment')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Comments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(IOSIcons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: StreamBuilder<List<StoryComment>>(
                stream: StoryService.instance
                    .watchStoryComments(storyId: widget.story.id),
                builder: (context, snapshot) {
                  final comments = snapshot.data ?? [];

                  if (comments.isEmpty) {
                    return const Center(
                      child: Text('No comments yet'),
                    );
                  }

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            c.authorUsername.isNotEmpty
                                ? c.authorUsername[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(c.authorUsername),
                        subtitle: Text(c.text),
                        trailing: Text(
                          _formatTimeAgo(c.createdAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_isSubmitting)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(IOSIcons.send),
                      onPressed: _submit,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendStorySheet extends StatelessWidget {
  final Story story;
  final VoidCallback onClose;

  const _SendStorySheet({
    required this.story,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Send to',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(IOSIcons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (currentUser == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Please sign in to share stories'),
              )
            else
              Flexible(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _watchUserChats(currentUser.uid),
                  builder: (context, snapshot) {
                    final chats = snapshot.data ?? [];

                    if (chats.isEmpty) {
                      return const Center(
                        child: Text('No recent chats'),
                      );
                    }

                    return ListView.builder(
                      itemCount: chats.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final chatId = chat['chatId'] as String;
                        final otherName = chat['otherName'] as String;

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              otherName.isNotEmpty
                                  ? otherName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(otherName),
                          onTap: () async {
                            try {
                              // Send story as a message
                              final storyPreview = story.mediaUrl != null
                                  ? 'Shared a story: ${story.text ?? "Story"}'
                                  : 'Shared a story: ${story.text ?? "Story"}';

                              await ChatService.instance.sendText(
                                chatId: chatId,
                                senderId: currentUser.uid,
                                text: storyPreview,
                              );

                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Story sent to $otherName'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to send story'),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _watchUserChats(String userId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('members', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .limit(20)
        .snapshots()
        .asyncMap((snap) async {
      final chats = <Map<String, dynamic>>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        final members = (data['members'] as List<dynamic>? ?? [])
            .cast<String>();
        final otherId = members.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        if (otherId.isEmpty) continue;

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherId)
            .get();

        final userData = userDoc.data();
        final name = userData?['username'] as String? ?? 'User';

        chats.add({
          'chatId': doc.id,
          'otherUser': otherId,
          'otherName': name,
        });
      }

      return chats;
    });
  }
}

String _formatTimeAgo(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
