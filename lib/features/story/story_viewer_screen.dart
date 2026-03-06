import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import 'package:just_audio/just_audio.dart';

import '../../models/story.dart';
import '../../models/story_comment.dart';
import '../../models/chat.dart';
import '../../models/story_sticker.dart';
import '../../services/chat_service.dart';
import '../../services/story_service.dart';
import '../../services/story_highlight_service.dart';
import '../../models/story_highlight.dart';
import '../../services/auth_service.dart';
import '../../services/user_cache_service.dart';
import '../../services/mute_service.dart';
import '../../services/report_service.dart';
import '../../theme/ios_icons.dart';
import '../../theme/app_themes.dart';
import '../../widgets/safe_network_image.dart';
import '../chat/video_player_screen.dart';
import 'create_story_screen.dart';

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

  late List<Story> _stories;
  bool get _isMine {
    final me = AuthService.instance.currentUser;
    if (me == null) return false;
    if (_stories.isEmpty) return false;
    return _stories.every((s) => s.authorId == me.id);
  }

  int get _pageCount => _isMine ? _stories.length + 1 : _stories.length;
  bool get _isAddPage => _isMine && _currentIndex == _stories.length;

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentMusicUrl;
  bool _musicPlaying = false;
  StreamSubscription<PlayerState>? _playerStateSub;
  late final AnimationController _progressController;
  bool _wasMusicPlayingBeforeHold = false;
  bool _musicLoading = false;
  String? _musicFailedUrl;

  final TextEditingController _quickReplyController = TextEditingController();
  bool _isSendingQuick = false;

  bool _loadingMuteState = false;
  bool _isAuthorMuted = false;
  String? _muteStateForAuthorId;

  static const _autoAdvanceDuration = Duration(seconds: 6);

  late final StreamSubscription<String> _userCacheSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _userCacheSub = UserCacheService.instance.updates.listen((_) {
      if (mounted) setState(() {});
    });

    _stories = List<Story>.from(widget.stories);

    if (_stories.isEmpty) {
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

    _currentIndex = widget.initialIndex.clamp(0, _stories.length - 1);
    _controller = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: _autoAdvanceDuration,
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        if (!mounted) return;
        if (_isAddPage) return;
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

    _loadMuteStateForCurrentStory();
  }

  Future<void> _loadMuteStateForCurrentStory() async {
    final me = AuthService.instance.currentUser;
    if (me == null) return;
    if (_stories.isEmpty) return;
    if (_isAddPage) return;

    final story = _stories[_currentIndex];
    if (story.authorId == me.id) return;

    if (_muteStateForAuthorId == story.authorId) return;
    _muteStateForAuthorId = story.authorId;

    setState(() {
      _loadingMuteState = true;
    });
    try {
      final muted = await MuteService.instance.isMuted(toUserId: story.authorId);
      if (!mounted) return;
      setState(() {
        _isAuthorMuted = muted;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingMuteState = false;
        });
      }
    }
  }

  Future<void> _toggleMuteCurrentAuthor() async {
    final me = AuthService.instance.currentUser;
    if (me == null) return;
    if (_stories.isEmpty || _isAddPage) return;
    final story = _stories[_currentIndex];
    if (story.authorId == me.id) return;

    if (_isAuthorMuted) {
      await MuteService.instance.unmute(fromUserId: me.id, toUserId: story.authorId);
      if (!mounted) return;
      setState(() {
        _isAuthorMuted = false;
      });
      return;
    }

    await MuteService.instance.mute(fromUserId: me.id, toUserId: story.authorId);
    if (!mounted) return;
    setState(() {
      _isAuthorMuted = true;
    });
  }

  Future<void> _reportCurrentStory() async {
    final me = AuthService.instance.currentUser;
    if (me == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to report stories.')),
      );
      return;
    }
    if (_stories.isEmpty || _isAddPage) return;
    final story = _stories[_currentIndex];

    final reasonController = TextEditingController();
    final detailsController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report story'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'Details (optional)'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    final reason = reasonController.text.trim();
    final details = detailsController.text.trim();
    if (reason.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reason is required.')),
      );
      return;
    }

    await ReportService.instance.report(
      targetType: 'story',
      targetId: story.id,
      reason: reason,
      details: details.isEmpty ? null : details,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted.')),
    );
  }

  Future<void> _refreshMyStoriesAndJumpToEnd() async {
    final me = AuthService.instance.currentUser;
    if (me == null) return;
    final next = await StoryService.instance.getUserStoriesOnce(authorId: me.id);
    if (!mounted) return;
    if (next.isEmpty) return;
    setState(() {
      _stories = next;
      _currentIndex = (_stories.length - 1).clamp(0, _stories.length - 1);
    });
    _controller.jumpToPage(_currentIndex);
    _markSeen(_currentIndex);
    _loadMusicForIndex(_currentIndex, autoPlay: true);
    _startProgressForIndex(_currentIndex);
  }

  Future<void> _openCreateStoryFromViewer() async {
    _pauseForHold();
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
    );
    if (!mounted) return;
    if (created == true) {
      await _refreshMyStoriesAndJumpToEnd();
    } else {
      _resumeAfterHold();
    }
  }

  Widget _buildAddStoryPage(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(IOSIcons.add, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add new story',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Swipe here and tap to create another story.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _openCreateStoryFromViewer,
            icon: const Icon(IOSIcons.add),
            label: const Text('Create story'),
          ),
        ],
      ),
    );
  }

  Future<void> _showLikes() async {
    if (_isAddPage) return;
    final story = _stories[_currentIndex];
    if (story.likedBy.isEmpty) return;

    _pauseForHold();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _StoryLikesSheet(
          userIds: story.likedBy,
          onClose: _resumeAfterHold,
        );
      },
    ).whenComplete(_resumeAfterHold);
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
    if (index < 0 || index >= _stories.length) return;
    final story = _stories[index];
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
    final me = AuthService.instance.currentUser;
    if (me == null) return;
    if (index < 0 || index >= _stories.length) return;
    final story = _stories[index];
    await StoryService.instance.markSeen(
      storyId: story.id,
      userId: me.id,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _playerStateSub?.cancel();
    _progressController.dispose();
    _audioPlayer.dispose();
    _userCacheSub.cancel();
    _quickReplyController.dispose();
    super.dispose();
  }

  void _startProgressForIndex(int index) {
    if (index < 0 || index >= _stories.length) return;
    final story = _stories[index];
    _progressController.stop();
    _progressController.value = 0;

    // Only auto-progress / auto-advance non-video stories.
    if (story.mediaType == 'video') {
      return;
    }
    _progressController.forward(from: 0);
  }

  void _goToNext() {
    if (_currentIndex >= _pageCount - 1) {
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
    final me = AuthService.instance.currentUser;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like stories')),
      );
      return;
    }
    final story = widget.stories[_currentIndex];
    await StoryService.instance.toggleLike(
      storyId: story.id,
      userId: me.id,
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
                  _goToNext();
                }
              },
              child: PageView.builder(
                controller: _controller,
                itemCount: _pageCount,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  if (_isAddPage) {
                    _progressController.stop();
                    _audioPlayer.pause();
                    _openCreateStoryFromViewer();
                    return;
                  }
                  _markSeen(index);
                  _loadMusicForIndex(index, autoPlay: true);
                  _startProgressForIndex(index);
                  _loadMuteStateForCurrentStory();
                },
                itemBuilder: (context, index) {
                  if (_isMine && index == _stories.length) {
                    return _buildAddStoryPage(context);
                  }
                  final story = _stories[index];
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
                              children: List.generate(_stories.length, (i) {
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
                      if (!_isMine && !_isAddPage)
                        PopupMenuButton<String>(
                          icon: const Icon(IOSIcons.moreVert, color: Colors.white),
                          onSelected: (v) async {
                            if (v == 'mute') {
                              await _toggleMuteCurrentAuthor();
                            } else if (v == 'report_story') {
                              await _reportCurrentStory();
                            }
                          },
                          itemBuilder: (context) {
                            final muteLabel = _loadingMuteState
                                ? 'Mute'
                                : (_isAuthorMuted ? 'Unmute user' : 'Mute user');
                            return [
                              PopupMenuItem(
                                value: 'mute',
                                enabled: !_loadingMuteState,
                                child: Row(
                                  children: [
                                    const Icon(IOSIcons.volumeOff, size: 18),
                                    const SizedBox(width: 8),
                                    Text(muteLabel),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'report_story',
                                child: Row(
                                  children: [
                                    Icon(IOSIcons.flag, size: 18),
                                    SizedBox(width: 8),
                                    Text('Report story'),
                                  ],
                                ),
                              ),
                            ];
                          },
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
              child: _buildBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canQuickReply {
    if (_isAddPage) return false;
    if (_stories.isEmpty) return false;
    final me = AuthService.instance.currentUser;
    if (me == null) return false;
    final story = _stories[_currentIndex];
    return story.authorId != me.id;
  }

  Future<String?> _ensureDirectChatWithAuthor() async {
    final me = AuthService.instance.currentUser;
    if (me == null) return null;
    if (_isAddPage) return null;
    if (_stories.isEmpty) return null;

    final story = _stories[_currentIndex];
    final author = await UserCacheService.instance.get(story.authorId);
    if (author.id.trim().isEmpty) return null;
    if (author.id == me.id) return null;

    try {
      final chatId = await ChatService.instance.createOrGetDirectChat(
        me: me,
        other: author,
      );
      return chatId;
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendQuickReaction(String emoji) async {
    if (!_canQuickReply) return;
    if (_isSendingQuick) return;

    setState(() {
      _isSendingQuick = true;
    });
    _pauseForHold();

    try {
      final chatId = await _ensureDirectChatWithAuthor();
      if (chatId == null) return;
      final me = AuthService.instance.currentUser;
      if (me == null) return;

      await ChatService.instance.sendText(
        chatId: chatId,
        senderId: me.id,
        text: '$emoji (reacted to your story)',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent $emoji')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingQuick = false;
        });
      }
      _resumeAfterHold();
    }
  }

  Future<void> _sendQuickReply() async {
    if (!_canQuickReply) return;
    if (_isSendingQuick) return;
    final text = _quickReplyController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSendingQuick = true;
    });
    _pauseForHold();

    try {
      final chatId = await _ensureDirectChatWithAuthor();
      if (chatId == null) return;
      final me = AuthService.instance.currentUser;
      if (me == null) return;

      await ChatService.instance.sendText(
        chatId: chatId,
        senderId: me.id,
        text: text,
      );

      _quickReplyController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply sent')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingQuick = false;
        });
      }
      _resumeAfterHold();
    }
  }

  Widget _buildHeaderInfo() {
    if (_isAddPage) {
      return Row(
        children: const [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white24,
            child: Icon(
              IOSIcons.add,
              size: 18,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Add to your story',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final story = _stories[_currentIndex];
    UserCacheService.instance.get(story.authorId);
    final author = UserCacheService.instance.peek(story.authorId);
    final authorAccent = AppThemes.seedFor(
      themeKey: author?.themeKey ?? story.authorThemeKey,
      themeSeedColor: author?.themeSeedColor ?? story.authorThemeSeedColor,
    );
    final authorPhotoUrl = author?.photoUrl;
    final username = story.authorUsername.isNotEmpty
        ? story.authorUsername
        : 'Story';
    final time = _formatTimeAgo(story.createdAt);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: authorAccent.withOpacity(0.75),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white24,
            child: ClipOval(
              child: (authorPhotoUrl != null && authorPhotoUrl.trim().isNotEmpty)
                  ? SafeNetworkImage(
                      url: authorPhotoUrl,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      IOSIcons.person,
                      size: 18,
                      color: authorAccent,
                    ),
            ),
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
        if (_isMine && !_isAddPage)
          IconButton(
            icon: const Icon(IOSIcons.bookmark, color: Colors.white),
            tooltip: 'Add to highlight',
            onPressed: _showAddToHighlight,
          ),
      ],
    );
  }

  Future<void> _showAddToHighlight() async {
    if (_isAddPage) return;
    final me = AuthService.instance.currentUser;
    if (me == null) return;

    final story = _stories[_currentIndex];
    if (story.authorId != me.id) return;

    _pauseForHold();

    List<StoryHighlight> highlights = const <StoryHighlight>[];
    try {
      highlights = await StoryHighlightService.instance
          .getUserHighlightsOnce(userId: me.id);
    } catch (_) {
      // swallow
    }

    if (!mounted) {
      _resumeAfterHold();
      return;
    }

    Future<void> createNewAndAdd() async {
      final controller = TextEditingController();
      try {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('New highlight'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Title'),
                maxLength: 80,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );

        if (ok != true) return;
        final title = controller.text.trim();
        if (title.isEmpty) return;
        final newId = await StoryHighlightService.instance.createHighlight(
          title: title,
        );
        await StoryHighlightService.instance.addStoryToHighlight(
          highlightId: newId,
          storyId: story.id,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to highlight.')),
        );
      } finally {
        controller.dispose();
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Create new highlight'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await createNewAndAdd();
                },
              ),
              if (highlights.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 6, 16, 16),
                  child: Text('No highlights yet.'),
                )
              else
                for (final h in highlights)
                  ListTile(
                    leading: const Icon(IOSIcons.bookmark),
                    title: Text(h.title),
                    subtitle: Text('${h.itemCount} stories'),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      try {
                        await StoryHighlightService.instance.addStoryToHighlight(
                          highlightId: h.id,
                          storyId: story.id,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to ${h.title}')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e')),
                        );
                      }
                    },
                  ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ).whenComplete(_resumeAfterHold);
  }

  Widget _buildStoryPage(BuildContext context, Story story) {
    final theme = Theme.of(context);

    switch (story.mediaType) {
      case 'image':
      case 'gif':
        if (story.mediaUrl == null || story.mediaUrl!.isEmpty) {
          return _buildStoryCanvas(context, story, child: _buildTextOnlyStory(context, story));
        }
        return _buildStoryCanvas(
          context,
          story,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeNetworkImage(
                url: story.mediaUrl,
                fit: BoxFit.cover,
                placeholder: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                error: const Center(
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
          ),
        );
      case 'video':
        if (story.mediaUrl == null || story.mediaUrl!.isEmpty) {
          return _buildStoryCanvas(context, story, child: _buildTextOnlyStory(context, story));
        }
        return _buildStoryCanvas(
          context,
          story,
          child: Stack(
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
          ),
        );
      case 'text':
      default:
        return _buildStoryCanvas(context, story, child: _buildTextOnlyStory(context, story));
    }
  }

  Widget _buildStoryCanvas(BuildContext context, Story story, {required Widget child}) {
    if (story.stickers.isEmpty) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            for (final st in story.stickers)
              _buildStickerWidget(
                context: context,
                story: story,
                sticker: st,
                canvasWidth: w,
                canvasHeight: h,
              ),
          ],
        );
      },
    );
  }

  Widget _buildStickerWidget({
    required BuildContext context,
    required Story story,
    required StorySticker sticker,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    const stickerWidth = 210.0;
    const stickerHeight = 64.0;

    final left = (sticker.posX * canvasWidth) - (stickerWidth / 2);
    final top = (sticker.posY * canvasHeight) - (stickerHeight / 2);

    final theme = Theme.of(context);

    Map<String, dynamic> data = const {};
    try {
      if ((sticker.dataJson ?? '').trim().isNotEmpty) {
        data = jsonDecode(sticker.dataJson!) as Map<String, dynamic>;
      }
    } catch (_) {
      data = const {};
    }

    String title = sticker.type;
    if (sticker.type == 'poll') {
      title = (data['question'] as String?) ?? 'Poll';
    } else if (sticker.type == 'question') {
      title = (data['prompt'] as String?) ?? 'Question';
    } else if (sticker.type == 'emoji_slider') {
      final emoji = (data['emoji'] as String?) ?? '🔥';
      final label = (data['label'] as String?) ?? '';
      title = label.trim().isEmpty ? emoji : '$emoji  $label';
    }

    String subtitle = '';
    if (sticker.type == 'poll') {
      if (sticker.myPollChoice != null) {
        subtitle = 'Voted';
      } else {
        subtitle = 'Tap to vote';
      }
    } else if (sticker.type == 'question') {
      final c = sticker.questionAnswerCount ?? 0;
      subtitle = c == 0 ? 'Tap to answer' : '$c answers';
    } else if (sticker.type == 'emoji_slider') {
      final cnt = sticker.emojiSliderCount ?? 0;
      subtitle = cnt == 0
          ? 'Tap to react'
          : 'Avg ${(sticker.emojiSliderAvg ?? 0).toStringAsFixed(1)} ($cnt)';
    }

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onStickerTap(story: story, sticker: sticker, data: data),
          child: Container(
            width: stickerWidth,
            height: stickerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onStickerTap({
    required Story story,
    required StorySticker sticker,
    required Map<String, dynamic> data,
  }) async {
    if (_isAddPage) return;
    _pauseForHold();

    try {
      if (sticker.type == 'poll') {
        final options = (data['options'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();
        if (options.isEmpty) return;
        final picked = await showModalBottomSheet<int>(
          context: context,
          showDragHandle: true,
          builder: (ctx) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Text(
                      (data['question'] as String?) ?? 'Poll',
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  for (var i = 0; i < options.length; i++)
                    ListTile(
                      title: Text(options[i]),
                      trailing: (sticker.myPollChoice == i)
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => Navigator.of(ctx).pop(i),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
        if (picked == null) return;
        await StoryService.instance.votePollSticker(
          storyId: story.id,
          stickerId: sticker.id,
          optionIndex: picked,
        );
      } else if (sticker.type == 'question') {
        final prompt = (data['prompt'] as String?) ?? 'Answer';
        final controller = TextEditingController(text: sticker.myQuestionAnswer);
        try {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: Text(prompt),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Your answer…'),
                  maxLines: 3,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Send'),
                  ),
                ],
              );
            },
          );
          if (ok != true) return;
          final answer = controller.text.trim();
          if (answer.isEmpty) return;
          await StoryService.instance.answerQuestionSticker(
            storyId: story.id,
            stickerId: sticker.id,
            answerText: answer,
          );
        } finally {
          controller.dispose();
        }
      } else if (sticker.type == 'emoji_slider') {
        int value = sticker.myEmojiSliderValue ?? 50;
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (context, setLocalState) {
                return AlertDialog(
                  title: Text((data['label'] as String?)?.trim().isNotEmpty == true
                      ? '${data['emoji'] ?? '🔥'}  ${data['label']}'
                      : (data['emoji'] as String?) ?? '🔥'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Slider(
                        value: value.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: '$value',
                        onChanged: (v) {
                          setLocalState(() {
                            value = v.round();
                          });
                        },
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
                      child: const Text('Send'),
                    ),
                  ],
                );
              },
            );
          },
        );
        if (ok != true) return;
        await StoryService.instance.setEmojiSliderStickerValue(
          storyId: story.id,
          stickerId: sticker.id,
          value: value,
        );
      }

      if (!mounted) return;
      setState(() {
        // trigger rebuild; actual results come from polling story refresh
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sent')),
      );
    } finally {
      _resumeAfterHold();
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

  Widget _buildBottomBar() {
    final story = widget.stories[_currentIndex];
    final currentUserId = AuthService.instance.currentUser?.id;
    final isLiked =
        currentUserId != null && story.likedBy.contains(currentUserId);

    final theme = Theme.of(context);
    final quickEmojis = <String>['❤️', '😂', '😮', '😢', '🔥', '👏'];

    final actionRow = Row(
      children: [
        GestureDetector(
          onTap: _toggleLike,
          onLongPress: _showLikes,
          child: Row(
            children: [
              Icon(
                isLiked ? IOSIcons.heartFill : IOSIcons.heart,
                color: isLiked ? Colors.redAccent : Colors.white,
                size: 28,
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _showLikes,
                child: Text(
                  '${story.likedBy.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: _showComments,
          child: const Icon(
            IOSIcons.chatBubbleOutline,
            color: Colors.white,
            size: 26,
          ),
        ),
        const Spacer(),
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

    if (!_canQuickReply) return actionRow;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              for (final e in quickEmojis)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _isSendingQuick ? null : () => _sendQuickReaction(e),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              const Spacer(),
              if (_isSendingQuick)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quickReplyController,
                  enabled: !_isSendingQuick,
                  onTap: _pauseForHold,
                  onSubmitted: (_) => _sendQuickReply(),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Reply…',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isSendingQuick ? null : _sendQuickReply,
                icon: const Icon(
                  IOSIcons.send,
                  color: Colors.white,
                  size: 18,
                ),
                tooltip: 'Send reply',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        actionRow,
        if (theme.platform == TargetPlatform.android)
          const SizedBox(height: 2),
      ],
    );
  }

}

class _StoryLikesSheet extends StatefulWidget {
  final List<String> userIds;
  final VoidCallback onClose;

  const _StoryLikesSheet({
    required this.userIds,
    required this.onClose,
  });

  @override
  State<_StoryLikesSheet> createState() => _StoryLikesSheetState();
}

class _StoryLikesSheetState extends State<_StoryLikesSheet> {
  late Future<List<AppUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadUsers(widget.userIds);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Container(
        height: height * 0.6,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  const Expanded(child: Text('Likes')),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onClose();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<AppUser>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final users = snapshot.data ?? const <AppUser>[];
                  if (users.isEmpty) {
                    return const Center(child: Text('No likes yet'));
                  }
                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final u = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceVariant,
                          child: ClipOval(
                            child: (u.photoUrl != null &&
                                    u.photoUrl!.trim().isNotEmpty)
                                ? SafeNetworkImage(
                                    url: u.photoUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Text(
                                      u.username.isNotEmpty
                                          ? u.username[0].toUpperCase()
                                          : 'U',
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(u.username),
                      );
                    },
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

Future<List<AppUser>> _loadUsers(List<String> ids) async {
  if (ids.isEmpty) return <AppUser>[];
  final parsed = ids.map(int.parse).toList();
  final qs = parsed.join(',');
  final rows = await AuthService.instance.api.getListOfMaps('/api/users?ids=$qs');
  return rows.map(AppUser.fromJson).toList();
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

  Future<void> _reportComment(StoryComment c) async {
    final me = AuthService.instance.currentUser;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to report comments')),
      );
      return;
    }

    final reasonController = TextEditingController();
    final detailsController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report comment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'Details (optional)'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Report'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;
    final reason = reasonController.text.trim();
    final details = detailsController.text.trim();
    if (reason.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reason is required.')),
      );
      return;
    }

    await ReportService.instance.report(
      targetType: 'story_comment',
      targetId: c.id,
      reason: reason,
      details: details.isEmpty ? null : details,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted.')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final me = AuthService.instance.currentUser;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await StoryService.instance.addComment(
        storyId: widget.story.id,
        authorId: me.id,
        authorUsername: me.username,
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
                      final accent = AppThemes.seedFor(
                        themeKey: c.authorThemeKey,
                        themeSeedColor: c.authorThemeSeedColor,
                      );
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: accent.withOpacity(0.12),
                          child: Text(
                            c.authorUsername.isNotEmpty
                                ? c.authorUsername[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          c.authorUsername,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(c.text),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'report') {
                              await _reportComment(c);
                            }
                          },
                          itemBuilder: (context) {
                            return const [
                              PopupMenuItem(
                                value: 'report',
                                child: Row(
                                  children: [
                                    Icon(IOSIcons.flag, size: 18),
                                    SizedBox(width: 8),
                                    Text('Report'),
                                  ],
                                ),
                              ),
                            ];
                          },
                          child: Text(
                            _formatTimeAgo(c.createdAt),
                            style: theme.textTheme.bodySmall,
                          ),
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
    final currentUser = AuthService.instance.currentUser;

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
                child: StreamBuilder<List<Chat>>(
                  stream: ChatService.instance.watchMyChats(uid: currentUser.id),
                  builder: (context, snapshot) {
                    final chats = snapshot.data ?? const <Chat>[];

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
                        final chatId = chat.id;

                        String displayName = chat.title ?? '';
                        if (!chat.isGroup) {
                          final otherId = chat.members.firstWhere(
                            (id) => id != currentUser.id,
                            orElse: () => '',
                          );
                          displayName = chat.memberUsernames[otherId] ?? displayName;
                        }
                        if (displayName.trim().isEmpty) {
                          displayName = chat.isGroup ? 'Group chat' : 'Chat';
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(displayName),
                          onTap: () async {
                            try {
                              // Send story as a message
                              final storyPreview = story.mediaUrl != null
                                  ? 'Shared a story: ${story.text ?? "Story"}'
                                  : 'Shared a story: ${story.text ?? "Story"}';

                              await ChatService.instance.sendText(
                                chatId: chatId,
                                senderId: currentUser.id,
                                text: storyPreview,
                              );

                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Story sent to $displayName'),
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
}

String _formatTimeAgo(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
