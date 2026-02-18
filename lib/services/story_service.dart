import 'dart:async';

import '../models/story.dart';
import '../models/story_comment.dart';
import 'auth_service.dart';

class StoryService {
  StoryService._();

  static final StoryService instance = StoryService._();

  /// Watch all non-expired stories ordered by creation time.
  Stream<List<Story>> watchActiveStories() {
    final controller = StreamController<List<Story>>();
    List<Story>? last;

    Future<void> tick() async {
      try {
        final rows = await AuthService.instance.api.getListOfMaps('/api/stories');
        final next = rows.map(Story.fromJson).toList();
        if (last == null || !_storiesEqual(last!, next)) {
          last = next;
          controller.add(next);
        }
      } catch (_) {
        // swallow errors
      }
    }

    tick();
    final timer = Timer.periodic(const Duration(seconds: 12), (_) => tick());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  /// Watch all non-expired stories for a single author.
  Stream<List<Story>> watchUserStories({required String authorId}) {
    final controller = StreamController<List<Story>>();
    List<Story>? last;

    Future<void> tick() async {
      try {
        final id = int.parse(authorId);
        final rows = await AuthService.instance.api
            .getListOfMaps('/api/stories/user/$id');
        final next = rows.map(Story.fromJson).toList();
        if (last == null || !_storiesEqual(last!, next)) {
          last = next;
          controller.add(next);
        }
      } catch (_) {
        // swallow
      }
    }

    tick();
    final timer = Timer.periodic(const Duration(seconds: 12), (_) => tick());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  Future<void> createTextStory({
    required String authorId,
    required String authorUsername,
    required String text,
    String? musicTitle,
    String? musicArtist,
    String? musicUrl,
  }) async {
    await AuthService.instance.api.postNoContent(
      '/api/stories',
      body: {
        'mediaType': 'text',
        'text': text,
        'musicTitle': musicTitle,
        'musicArtist': musicArtist,
        'musicUrl': musicUrl,
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
    final controller = StreamController<List<StoryComment>>();
    List<StoryComment>? last;

    Future<void> tick() async {
      try {
        final rows = await AuthService.instance.api
            .getListOfMaps('/api/stories/$storyId/comments');
        final next = rows.map(StoryComment.fromJson).toList();
        if (last == null || !_storyCommentsEqual(last!, next)) {
          last = next;
          controller.add(next);
        }
      } catch (_) {
        // swallow
      }
    }

    tick();
    final timer = Timer.periodic(const Duration(seconds: 8), (_) => tick());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
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

  bool _storiesEqual(List<Story> a, List<Story> b) {
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

  bool _storyCommentsEqual(List<StoryComment> a, List<StoryComment> b) {
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
