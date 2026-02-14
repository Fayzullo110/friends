import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';

import '../../models/user_status.dart';
import '../../services/user_status_service.dart';
import '../../theme/ios_icons.dart';

class StatusViewerScreen extends StatefulWidget {
  final List<UserStatus> statuses;
  final int initialIndex;

  const StatusViewerScreen({
    super.key,
    required this.statuses,
    this.initialIndex = 0,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _controller;
  int _currentIndex = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentMusicUrl;
  bool _musicPlaying = false;
  late final AnimationController _progressController;
  bool _wasMusicPlayingBeforeHold = false;

  static const _autoAdvanceDuration = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.statuses.length - 1);
    _controller = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: _autoAdvanceDuration,
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        if (!mounted) return;
        _goToNext();
      });

    _markSeen(_currentIndex);
    _loadMusicForIndex(_currentIndex, autoPlay: true);
    _startProgressForIndex(_currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadMusicForIndex(int index, {required bool autoPlay}) async {
    if (index < 0 || index >= widget.statuses.length) return;
    final status = widget.statuses[index];
    final url = status.musicUrl;

    if (url == null || url.isEmpty) {
      await _audioPlayer.stop();
      setState(() {
        _currentMusicUrl = null;
        _musicPlaying = false;
      });
      return;
    }

    if (_currentMusicUrl != url) {
      try {
        await _audioPlayer.setUrl(url);
        _currentMusicUrl = url;
      } catch (_) {
        await _audioPlayer.stop();
        if (!mounted) return;
        setState(() {
          _currentMusicUrl = null;
          _musicPlaying = false;
        });
        return;
      }
    }

    if (autoPlay) {
      try {
        await _audioPlayer.play();
        setState(() => _musicPlaying = true);
      } catch (_) {
        setState(() => _musicPlaying = false);
      }
    }
  }

  Future<void> _markSeen(int index) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;
    if (index < 0 || index >= widget.statuses.length) return;
    final status = widget.statuses[index];
    await UserStatusService.instance.markSeen(
      statusId: status.id,
      userId: authUser.uid,
    );
  }

  void _startProgressForIndex(int index) {
    _progressController.stop();
    _progressController.value = 0;
    _progressController.forward(from: 0);
  }

  void _goToNext() {
    if (_currentIndex >= widget.statuses.length - 1) {
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
    if (_progressController.value < 1.0) {
      _progressController.forward();
    }
    if (_wasMusicPlayingBeforeHold) {
      _audioPlayer.play();
    }
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
                  _goToPrevious();
                } else {
                  if (_currentIndex < widget.statuses.length - 1) {
                    _goToNext();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                }
              },
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.statuses.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  _markSeen(index);
                  _loadMusicForIndex(index, autoPlay: true);
                  _startProgressForIndex(index);
                },
                itemBuilder: (context, index) {
                  final status = widget.statuses[index];
                  return _buildStatusPage(context, status);
                },
              ),
            ),
            // Top header
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
                              children: List.generate(widget.statuses.length, (i) {
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
                  const SizedBox(height: 16),
                  _buildHeaderInfo(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final status = widget.statuses[_currentIndex];
    final time = _formatTimeAgo(status.createdAt);

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white24,
          backgroundImage: status.photoUrl != null
              ? NetworkImage(status.photoUrl!)
              : null,
          child: status.photoUrl == null
              ? Text(
                  status.username.isNotEmpty
                      ? status.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status.username,
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
            ],
          ),
        ),
        if (status.hasMusic)
          IconButton(
            icon: Icon(
              _musicPlaying ? IOSIcons.pause : IOSIcons.play,
              color: Colors.white,
            ),
            onPressed: () async {
              if (_musicPlaying) {
                await _audioPlayer.pause();
                setState(() => _musicPlaying = false);
              } else {
                await _audioPlayer.play();
                setState(() => _musicPlaying = true);
              }
            },
          ),
      ],
    );
  }

  Widget _buildStatusPage(BuildContext context, UserStatus status) {
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
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status.hasEmoji)
                Text(
                  status.emoji!,
                  style: const TextStyle(fontSize: 80),
                ),
              if (status.text.isNotEmpty)
                Text(
                  status.text,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (status.hasMusic)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IOSIcons.musicNote,
                          color: Colors.white.withOpacity(0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${status.musicTitle!} • ${status.musicArtist!}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
