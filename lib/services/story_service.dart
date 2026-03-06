import 'dart:async';

import '../models/story.dart';
import '../models/story_comment.dart';
import '../models/story_sticker.dart';
import 'auth_service.dart';

class StoryService {
  StoryService._();

  static final StoryService instance = StoryService._();

  _StoryPoller? _activePoller;
  final Map<String, _StoryPoller> _userPollers = <String, _StoryPoller>{};
  final Map<String, _StoryCommentsPoller> _storyCommentPollers =
      <String, _StoryCommentsPoller>{};

  /// Watch all non-expired stories ordered by creation time.
  Stream<List<Story>> watchActiveStories() {
    _activePoller ??= _StoryPoller(
      key: '__active__',
      fetch: () async {
        final rows = await AuthService.instance.api.getListOfMaps('/api/stories');
        return rows.map(Story.fromJson).toList();
      },
      onZeroListeners: () {
        _activePoller = null;
      },
    );
    return _activePoller!.stream;
  }

  Future<List<Story>> getUserStoriesOnce({required String authorId}) async {
    final id = int.parse(authorId);
    final rows = await AuthService.instance.api.getListOfMaps(
      '/api/stories/user/$id',
    );
    return rows.map(Story.fromJson).toList();
  }

  /// Watch all non-expired stories for a single author.
  Stream<List<Story>> watchUserStories({required String authorId}) {
    final trimmed = authorId.trim();
    final poller = _userPollers.putIfAbsent(trimmed, () {
      return _StoryPoller(
        key: trimmed,
        fetch: () async {
          final id = int.parse(trimmed);
          final rows = await AuthService.instance.api
              .getListOfMaps('/api/stories/user/$id');
          return rows.map(Story.fromJson).toList();
        },
        onZeroListeners: () {
          _userPollers.remove(trimmed);
        },
      );
    });
    return poller.stream;
  }

  Future<void> createTextStory({
    required String authorId,
    required String authorUsername,
    required String text,
    String? musicTitle,
    String? musicArtist,
    String? musicUrl,
    List<StorySticker>? stickers,
  }) async {
    await AuthService.instance.api.postNoContent(
      '/api/stories',
      body: {
        'mediaType': 'text',
        'text': text,
        'musicTitle': musicTitle,
        'musicArtist': musicArtist,
        'musicUrl': musicUrl,
        'stickers': (stickers ?? const [])
            .map(
              (s) => {
                'type': s.type,
                'posX': s.posX,
                'posY': s.posY,
                'dataJson': s.dataJson,
              },
            )
            .toList(),
      },
    );
  }

  Future<void> createMediaStory({
    required String authorId,
    required String authorUsername,
    required String mediaUrl,
    required String mediaType, // 'image', 'video', or 'gif'
    String? text,
    String? musicTitle,
    String? musicArtist,
    String? musicUrl,
    List<StorySticker>? stickers,
  }) async {
    await AuthService.instance.api.postNoContent(
      '/api/stories',
      body: {
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'text': text,
        'musicTitle': musicTitle,
        'musicArtist': musicArtist,
        'musicUrl': musicUrl,
        'stickers': (stickers ?? const [])
            .map(
              (s) => {
                'type': s.type,
                'posX': s.posX,
                'posY': s.posY,
                'dataJson': s.dataJson,
              },
            )
            .toList(),
      },
    );
  }

  Future<void> votePollSticker({
    required String storyId,
    required String stickerId,
    required int optionIndex,
  }) async {
    await AuthService.instance.api.postNoContent(
      '/api/stories/$storyId/stickers/$stickerId/poll-vote',
      body: {
        'optionIndex': optionIndex,
      },
    );
  }

  Future<void> answerQuestionSticker({
    required String storyId,
    required String stickerId,
    required String answerText,
  }) async {
    await AuthService.instance.api.postNoContent(
      '/api/stories/$storyId/stickers/$stickerId/question-answer',
      body: {
        'answerText': answerText,
      },
    );
  }

  Future<void> setEmojiSliderStickerValue({
    required String storyId,
    required String stickerId,
    required int value,
  }) async {
    await AuthService.instance.api.postNoContent(
      '/api/stories/$storyId/stickers/$stickerId/emoji-slider',
      body: {
        'value': value,
      },
    );
  }

  Future<void> markSeen({
    required String storyId,
    required String userId,
  }) async {
    await AuthService.instance.api.postNoContent('/api/stories/$storyId/seen');
  }

  /// Toggle like on a story (like if not liked, unlike if already liked)
  Future<void> toggleLike({
    required String storyId,
    required String userId,
  }) async {
    await AuthService.instance.api.postNoContent('/api/stories/$storyId/like');
  }

  /// Watch comments for a specific story
  Stream<List<StoryComment>> watchStoryComments({required String storyId}) {
    final key = storyId.trim();
    final poller = _storyCommentPollers.putIfAbsent(key, () {
      return _StoryCommentsPoller(
        key: key,
        fetch: () async {
          final rows = await AuthService.instance.api
              .getListOfMaps('/api/stories/$key/comments');
          return rows.map(StoryComment.fromJson).toList();
        },
        onZeroListeners: () {
          _storyCommentPollers.remove(key);
        },
      );
    });
    return poller.stream;
  }

  /// Add a comment to a story
  Future<void> addComment({
    required String storyId,
    required String authorId,
    required String authorUsername,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await AuthService.instance.api.postNoContent(
      '/api/stories/$storyId/comments',
      body: {'text': trimmed},
    );
  }

  /// Delete a comment (only the author can delete)
  Future<void> deleteComment({
    required String storyId,
    required String commentId,
    required String userId,
  }) async {
    await AuthService.instance.api
        .deleteNoContent('/api/stories/$storyId/comments/$commentId');
  }
}

class _StoryCommentsPoller {
  final String key;
  final Future<List<StoryComment>> Function() fetch;
  final void Function() onZeroListeners;

  _StoryCommentsPoller({
    required this.key,
    required this.fetch,
    required this.onZeroListeners,
  }) {
    _controller = StreamController<List<StoryComment>>.broadcast(
      onListen: _handleListen,
      onCancel: _handleCancel,
    );
  }

  late final StreamController<List<StoryComment>> _controller;
  Timer? _timer;
  int _listeners = 0;
  bool _tickInFlight = false;
  List<StoryComment>? _last;

  Stream<List<StoryComment>> get stream => _controller.stream;

  void _handleListen() {
    _listeners += 1;
    _timer ??= Timer.periodic(const Duration(seconds: 8), (_) => _tick());
    _tick();
  }

  void _handleCancel() {
    _listeners = (_listeners - 1).clamp(0, 1 << 30);
    if (_listeners > 0) return;
    _timer?.cancel();
    _timer = null;
    _controller.close();
    onZeroListeners();
  }

  Future<void> _tick() async {
    if (_tickInFlight) return;
    _tickInFlight = true;
    try {
      final next = await fetch();
      if (_last == null || !_storyCommentsEqualStatic(_last!, next)) {
        _last = next;
        if (!_controller.isClosed) {
          _controller.add(next);
        }
      }
    } catch (_) {
      // swallow
    } finally {
      _tickInFlight = false;
    }
  }

  static bool _storyCommentsEqualStatic(List<StoryComment> a, List<StoryComment> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final ca = a[i];
      final cb = b[i];
      if (ca.id != cb.id) return false;
      if (ca.text != cb.text) return false;
      if (ca.createdAt != cb.createdAt) return false;
    }
    return true;
  }
}

class _StoryPoller {
  final String key;
  final Future<List<Story>> Function() fetch;
  final void Function() onZeroListeners;

  _StoryPoller({
    required this.key,
    required this.fetch,
    required this.onZeroListeners,
  }) {
    _controller = StreamController<List<Story>>.broadcast(
      onListen: _handleListen,
      onCancel: _handleCancel,
    );
  }

  late final StreamController<List<Story>> _controller;
  Timer? _timer;
  int _listeners = 0;
  bool _tickInFlight = false;
  List<Story>? _last;

  Stream<List<Story>> get stream => _controller.stream;

  void _handleListen() {
    _listeners += 1;
    _timer ??= Timer.periodic(const Duration(seconds: 12), (_) => _tick());
    _tick();
  }

  void _handleCancel() {
    _listeners = (_listeners - 1).clamp(0, 1 << 30);
    if (_listeners > 0) return;
    _timer?.cancel();
    _timer = null;
    _controller.close();
    onZeroListeners();
  }

  Future<void> _tick() async {
    if (_tickInFlight) return;
    _tickInFlight = true;
    try {
      final next = await fetch();
      if (_last == null || !_storiesEqualStatic(_last!, next)) {
        _last = next;
        if (!_controller.isClosed) {
          _controller.add(next);
        }
      }
    } catch (_) {
      // swallow
    } finally {
      _tickInFlight = false;
    }
  }

  static bool _storiesEqualStatic(List<Story> a, List<Story> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final sa = a[i];
      final sb = b[i];
      if (sa.id != sb.id) return false;
      if (sa.mediaUrl != sb.mediaUrl) return false;
      if (sa.mediaType != sb.mediaType) return false;
      if (sa.text != sb.text) return false;
      if (sa.likedBy.length != sb.likedBy.length) return false;
      if (sa.seenBy.length != sb.seenBy.length) return false;
    }
    return true;
  }
}
