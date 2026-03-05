import 'dart:async';

import '../models/comment.dart';
import 'auth_service.dart';

class CommentService {
  CommentService._();

  static final CommentService instance = CommentService._();

  final Map<String, _CommentsPoller> _postPollers = <String, _CommentsPoller>{};
  final Map<String, _CommentsPoller> _reelPollers = <String, _CommentsPoller>{};

  Stream<List<Comment>> watchComments({required String postId}) {
    final key = postId.trim();
    final poller = _postPollers.putIfAbsent(key, () {
      return _CommentsPoller(
        key: key,
        fetch: () async {
          final rows = await AuthService.instance.api
              .getListOfMaps('/api/posts/$key/comments');
          return rows.map(Comment.fromJson).toList();
        },
        onZeroListeners: () {
          _postPollers.remove(key);
        },
      );
    });
    return poller.stream;
  }

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorUsername,
    required String text,
    String? parentCommentId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await AuthService.instance.api.postNoContent(
      '/api/posts/$postId/comments',
      body: {
        'text': trimmed,
        'type': 'text',
        'parentCommentId': parentCommentId,
      },
    );
  }

  Stream<List<Comment>> watchReelComments({required String reelId}) {
    final key = reelId.trim();
    final poller = _reelPollers.putIfAbsent(key, () {
      return _CommentsPoller(
        key: key,
        fetch: () async {
          final rows = await AuthService.instance.api
              .getListOfMaps('/api/reels/$key/comments');
          return rows.map(_reelCommentFromJson).toList();
        },
        onZeroListeners: () {
          _reelPollers.remove(key);
        },
      );
    });
    return poller.stream;
  }

  Future<void> addReelComment({
    required String reelId,
    required String authorId,
    required String authorUsername,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await AuthService.instance.api.postNoContent(
      '/api/reels/$reelId/comments',
      body: {
        'text': trimmed,
        'type': 'text',
      },
    );
  }

  Future<void> addReelGifComment({
    required String reelId,
    required String authorId,
    required String authorUsername,
    required String gifUrl,
  }) async {
    if (gifUrl.isEmpty) return;

    await AuthService.instance.api.postNoContent(
      '/api/reels/$reelId/comments',
      body: {
        'text': '',
        'type': 'gif',
        'mediaUrl': gifUrl,
      },
    );
  }

  Future<void> toggleLikeReelComment({
    required String reelId,
    required String commentId,
    required String userId,
  }) async {
    await AuthService.instance.api
        .postNoContent('/api/reels/$reelId/comments/$commentId/like');
  }

  Future<void> toggleDislikeReelComment({
    required String reelId,
    required String commentId,
    required String userId,
  }) async {
    await AuthService.instance.api
        .postNoContent('/api/reels/$reelId/comments/$commentId/dislike');
  }

  Comment _reelCommentFromJson(Map<String, dynamic> data) {
    return Comment(
      id: data['id'].toString(),
      postId: data['reelId'].toString(),
      authorId: data['authorId'].toString(),
      authorUsername: data['authorUsername'] as String? ?? '',
      text: data['text'] as String? ?? '',
      type: (data['type'] as String?) == 'gif' ? CommentType.gif : CommentType.text,
      mediaUrl: data['mediaUrl'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
        isUtc: false,
      ),
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      likedBy: (data['likedBy'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      parentCommentId: null,
      dislikeCount: (data['dislikeCount'] as num?)?.toInt() ?? 0,
      dislikedBy: (data['dislikedBy'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Future<void> addGifComment({
    required String postId,
    required String authorId,
    required String authorUsername,
    required String gifUrl,
    String? parentCommentId,
  }) async {
    if (gifUrl.isEmpty) return;

    await AuthService.instance.api.postNoContent(
      '/api/posts/$postId/comments',
      body: {
        'text': '',
        'type': 'gif',
        'mediaUrl': gifUrl,
        'parentCommentId': parentCommentId,
      },
    );
  }

  Future<void> toggleLikeComment({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    await AuthService.instance.api
        .postNoContent('/api/posts/$postId/comments/$commentId/like');
  }

  Future<void> toggleDislikeComment({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    await AuthService.instance.api
        .postNoContent('/api/posts/$postId/comments/$commentId/dislike');
  }
}

class _CommentsPoller {
  final String key;
  final Future<List<Comment>> Function() fetch;
  final void Function() onZeroListeners;

  _CommentsPoller({
    required this.key,
    required this.fetch,
    required this.onZeroListeners,
  }) {
    _controller = StreamController<List<Comment>>.broadcast(
      onListen: _handleListen,
      onCancel: _handleCancel,
    );
  }

  late final StreamController<List<Comment>> _controller;
  Timer? _timer;
  int _listeners = 0;
  bool _tickInFlight = false;
  List<Comment>? _last;

  Stream<List<Comment>> get stream => _controller.stream;

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
      if (_last == null || !_commentsEqualStatic(_last!, next)) {
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

  static bool _commentsEqualStatic(List<Comment> a, List<Comment> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final ca = a[i];
      final cb = b[i];
      if (ca.id != cb.id) return false;
      if (ca.text != cb.text) return false;
      if (ca.type != cb.type) return false;
      if (ca.mediaUrl != cb.mediaUrl) return false;
      if (ca.likeCount != cb.likeCount) return false;
      if (ca.dislikeCount != cb.dislikeCount) return false;
    }
    return true;
  }
}
