import 'dart:async';

import '../models/reel.dart';
import 'auth_service.dart';

class ReelService {
  ReelService._();

  static final ReelService instance = ReelService._();

  Stream<List<Reel>> watchReels() {
    final controller = StreamController<List<Reel>>();
    List<Reel>? last;

    Future<void> tick() async {
      try {
        final rows = await AuthService.instance.api.getListOfMaps('/api/reels');
        final next = rows.map(Reel.fromJson).toList();
        if (last == null || !_reelsEqual(last!, next)) {
          last = next;
          controller.add(next);
        }
      } catch (_) {
        // swallow errors
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

  Stream<List<Reel>> watchArchivedReels({required String uid}) {
    final controller = StreamController<List<Reel>>();
    List<Reel>? last;

    Future<void> tick() async {
      try {
        final rows = await AuthService.instance.api.getListOfMaps('/api/reels/archived');
        final next = rows.map(Reel.fromJson).toList();
        if (last == null || !_reelsEqual(last!, next)) {
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

  bool _reelsEqual(List<Reel> a, List<Reel> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final ra = a[i];
      final rb = b[i];
      if (ra.id != rb.id) return false;
      if (ra.likeCount != rb.likeCount) return false;
      if (ra.commentCount != rb.commentCount) return false;
      if (ra.shareCount != rb.shareCount) return false;
      if (ra.caption != rb.caption) return false;
      if (ra.mediaUrl != rb.mediaUrl) return false;
    }
    return true;
  }

  Future<void> createTextReel({
    required String authorId,
    required String authorUsername,
    required String caption,
  }) async {
    await AuthService.instance.api.postNoContent(
      '/api/reels',
      body: {
        'caption': caption,
        'mediaType': 'text',
      },
    );
  }

  Future<void> toggleLike({
    required String reelId,
    required String userId,
  }) async {
    await AuthService.instance.api.postNoContent('/api/reels/$reelId/like');
  }

  Future<void> incrementShareCount({required String reelId}) async {
    await AuthService.instance.api.postNoContent('/api/reels/$reelId/share');
  }

  Future<Reel> updateReel({required String reelId, required String caption}) async {
    final trimmed = caption.trim();
    if (trimmed.isEmpty) throw Exception('Caption cannot be empty');
    return await AuthService.instance.api.patchJson(
      '/api/reels/$reelId',
      {'caption': trimmed},
      (json) => Reel.fromJson(json),
    );
  }

  Future<void> archiveReel({required String reelId}) async {
    await AuthService.instance.api.postNoContent('/api/reels/$reelId/archive');
  }

  Future<void> restoreReel({required String reelId}) async {
    await AuthService.instance.api.postNoContent('/api/reels/$reelId/restore');
  }

  Future<void> deleteReel({required String reelId}) async {
    await AuthService.instance.api.deleteNoContent('/api/reels/$reelId');
  }

  Future<void> repost({
    required String sourceReelId,
    required String newAuthorId,
    required String newAuthorUsername,
  }) async {
    // Backend doesn't currently support repost; treat as share for now.
    await incrementShareCount(reelId: sourceReelId);
  }

  Future<Reel> getReelById({required String reelId}) async {
    return await AuthService.instance.api.getJson(
      '/api/reels/$reelId',
      (json) => Reel.fromJson(json),
    );
  }
}
