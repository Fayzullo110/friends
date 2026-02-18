import 'dart:async';

import '../models/post.dart';
import 'auth_service.dart';

class PostService {
  PostService._();

  static final PostService instance = PostService._();

  Stream<List<Post>> watchRecentPosts() {
    final controller = StreamController<List<Post>>();
    List<Post>? last;

    Future<void> tick() async {
      try {
        final rows = await AuthService.instance.api.getListOfMaps('/api/posts');
        final next = rows.map(Post.fromJson).toList();
        if (last == null || !_postsEqual(last!, next)) {
          last = next;
          controller.add(next);
        }
      } catch (_) {
        // swallow errors to keep UI alive
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

  Stream<List<Post>> watchArchivedPosts({required String uid}) {
    final controller = StreamController<List<Post>>();
    List<Post>? last;

    Future<void> tick() async {
      try {
        final rows = await AuthService.instance.api.getListOfMaps('/api/posts/archived');
        final next = rows.map(Post.fromJson).toList();
        if (last == null || !_postsEqual(last!, next)) {
          last = next;
          controller.add(next);
        }
      } catch (_) {
        // swallow
      }
    }

    tick();
    final timer = Timer.periodic(const Duration(seconds: 10), (_) => tick());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  Future<void> createTextPost({
    required String authorId,
    required String authorUsername,
    required String text,
  }) async {
    await AuthService.instance.api.postNoContent(
      '/api/posts',
      body: {
        'text': text,
        'mediaType': 'text',
      },
    );
  }

  Future<void> createMediaPost({
    required String authorId,
    required String authorUsername,
    required String text,
    required String mediaUrl,
    required String mediaType, // 'image' or 'video'
  }) async {
    await AuthService.instance.api.postNoContent(
      '/api/posts',
      body: {
        'text': text,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
      },
    );
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    await AuthService.instance.api.postNoContent('/api/posts/$postId/like');
  }

  Future<void> setPinnedComment({
    required String postId,
    String? commentId,
  }) async {
    if (commentId == null || commentId.isEmpty) {
      await AuthService.instance.api.postNoContent('/api/posts/$postId/unpin');
      return;
    }
    await AuthService.instance.api.postNoContent('/api/posts/$postId/pin/$commentId');
  }

  Future<void> incrementShareCount({required String postId}) async {
    await AuthService.instance.api.postNoContent('/api/posts/$postId/share');
  }

  Future<void> repost({
    required String sourcePostId,
    required String newAuthorId,
    required String newAuthorUsername,
  }) async {
    // Backend doesn't currently support repost; treat as share for now.
    await incrementShareCount(postId: sourcePostId);
  }

  Future<Post> updatePost({required String postId, required String text}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw Exception('Text cannot be empty');
    return await AuthService.instance.api.patchJson(
      '/api/posts/$postId',
      {'text': trimmed},
      (json) => Post.fromJson(json),
    );
  }

  Future<void> archivePost({required String postId}) async {
    await AuthService.instance.api.postNoContent('/api/posts/$postId/archive');
  }

  Future<void> restorePost({required String postId}) async {
    await AuthService.instance.api.postNoContent('/api/posts/$postId/restore');
  }

  Future<void> deletePost({required String postId}) async {
    await AuthService.instance.api.deleteNoContent('/api/posts/$postId');
  }

  Future<Post> getPostById({required String postId}) async {
    return await AuthService.instance.api.getJson(
      '/api/posts/$postId',
      (json) => Post.fromJson(json),
    );
  }
}

bool _postsEqual(List<Post> a, List<Post> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final pa = a[i];
    final pb = b[i];
    if (pa.id != pb.id) return false;
    if (pa.likeCount != pb.likeCount) return false;
    if (pa.commentCount != pb.commentCount) return false;
    if (pa.shareCount != pb.shareCount) return false;
    if (pa.text != pb.text) return false;
    if (pa.mediaUrl != pb.mediaUrl) return false;
  }
  return true;
}
