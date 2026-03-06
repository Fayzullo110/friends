import 'dart:async';

import '../models/story.dart';
import '../models/story_highlight.dart';
import 'auth_service.dart';

class StoryHighlightService {
  StoryHighlightService._();

  static final StoryHighlightService instance = StoryHighlightService._();

  final Map<String, _HighlightsPoller> _pollers = <String, _HighlightsPoller>{};

  Stream<List<StoryHighlight>> watchUserHighlights({required String userId}) {
    final key = userId.trim();
    final poller = _pollers.putIfAbsent(key, () {
      return _HighlightsPoller(
        key: key,
        fetch: () async {
          final uid = int.parse(key);
          final rows = await AuthService.instance.api
              .getListOfMaps('/api/story-highlights/user/$uid');
          return rows.map(StoryHighlight.fromJson).toList();
        },
        onZeroListeners: () {
          _pollers.remove(key);
        },
      );
    });
    return poller.stream;
  }

  Future<List<StoryHighlight>> getUserHighlightsOnce({required String userId}) async {
    final uid = int.parse(userId.trim());
    final rows = await AuthService.instance.api
        .getListOfMaps('/api/story-highlights/user/$uid');
    return rows.map(StoryHighlight.fromJson).toList();
  }

  Future<List<Story>> getHighlightStoriesOnce({required String highlightId}) async {
    final hid = int.parse(highlightId);
    final rows = await AuthService.instance.api
        .getListOfMaps('/api/story-highlights/$hid/stories');
    return rows.map(Story.fromJson).toList();
  }

  Future<String> createHighlight({required String title}) async {
    final json = await AuthService.instance.api.postJson(
      '/api/story-highlights',
      {
        'title': title.trim(),
      },
      (json) => json,
    );
    return (json['id']).toString();
  }

  Future<void> addStoryToHighlight({
    required String highlightId,
    required String storyId,
    int? position,
  }) async {
    final hid = int.parse(highlightId);
    final sid = int.parse(storyId);
    await AuthService.instance.api.postNoContent(
      '/api/story-highlights/$hid/items',
      body: {
        'storyId': sid,
        'position': position,
      },
    );
  }

  Future<void> removeStoryFromHighlight({
    required String highlightId,
    required String storyId,
  }) async {
    final hid = int.parse(highlightId);
    final sid = int.parse(storyId);
    await AuthService.instance.api
        .deleteNoContent('/api/story-highlights/$hid/items/$sid');
  }

  Future<void> deleteHighlight({required String highlightId}) async {
    final hid = int.parse(highlightId);
    await AuthService.instance.api.deleteNoContent('/api/story-highlights/$hid');
  }

  Future<void> renameHighlight({
    required String highlightId,
    required String title,
  }) async {
    final hid = int.parse(highlightId);
    await AuthService.instance.api.patchNoContent(
      '/api/story-highlights/$hid',
      body: {
        'title': title.trim(),
      },
    );
  }

  Future<void> reorderHighlightItems({
    required String highlightId,
    required List<String> orderedStoryIds,
  }) async {
    final hid = int.parse(highlightId);
    await AuthService.instance.api.postNoContent(
      '/api/story-highlights/$hid/reorder',
      body: {
        'items': [
          for (var i = 0; i < orderedStoryIds.length; i++)
            {
              'storyId': int.parse(orderedStoryIds[i]),
              'position': i,
            },
        ],
      },
    );
  }
}

class _HighlightsPoller {
  final String key;
  final Future<List<StoryHighlight>> Function() fetch;
  final void Function() onZeroListeners;

  _HighlightsPoller({
    required this.key,
    required this.fetch,
    required this.onZeroListeners,
  }) {
    _controller = StreamController<List<StoryHighlight>>.broadcast(
      onListen: _handleListen,
      onCancel: _handleCancel,
    );
  }

  late final StreamController<List<StoryHighlight>> _controller;
  Timer? _timer;
  int _listeners = 0;
  bool _tickInFlight = false;
  List<StoryHighlight>? _last;

  Stream<List<StoryHighlight>> get stream => _controller.stream;

  void _handleListen() {
    _listeners += 1;
    _timer ??= Timer.periodic(const Duration(seconds: 15), (_) => _tick());
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
      if (_last == null || !_highlightsEqualStatic(_last!, next)) {
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

  static bool _highlightsEqualStatic(List<StoryHighlight> a, List<StoryHighlight> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final ha = a[i];
      final hb = b[i];
      if (ha.id != hb.id) return false;
      if (ha.updatedAt != hb.updatedAt) return false;
      if (ha.itemCount != hb.itemCount) return false;
    }
    return true;
  }
}
