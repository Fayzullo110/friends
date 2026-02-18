import 'dart:async';

import 'auth_service.dart';

class BlockService {
  BlockService._();
  static final BlockService instance = BlockService._();

  // Polling stream until we add realtime via websockets.
  Stream<List<String>> watchBlocked({required String uid}) async* {
    List<String>? last;
    while (true) {
      final next = await getBlockedOnce(uid: uid);
      next.sort();
      if (last == null || !_listEquals(last, next)) {
        last = next;
        yield next;
      }
      await Future<void>.delayed(const Duration(seconds: 10));
    }
  }

  Future<List<String>> getBlockedOnce({required String uid}) async {
    // Backend uses JWT for identity; uid param is ignored but kept for compatibility.
    final list = await AuthService.instance.api.getList('/api/blocks');
    return list.map((e) => e.toString()).toList();
  }

  Future<void> block({required String fromUserId, required String toUserId}) async {
    if (fromUserId == toUserId) return;
    final target = int.parse(toUserId);
    await AuthService.instance.api.postNoContent('/api/blocks/$target');
  }

  Future<void> unblock({required String fromUserId, required String toUserId}) async {
    final target = int.parse(toUserId);
    await AuthService.instance.api.deleteNoContent('/api/blocks/$target');
  }

  Future<bool> isBlocked({
    required String fromUserId,
    required String toUserId,
  }) async {
    // Supports checking:
    // - me -> other
    // - other -> me
    final me = AuthService.instance.currentUser;
    if (me == null) return false;

    if (fromUserId == me.id) {
      final target = int.parse(toUserId);
      return await AuthService.instance.api.getBool('/api/blocks/$target/exists');
    }

    if (toUserId == me.id) {
      final other = int.parse(fromUserId);
      return await AuthService.instance.api.getBool('/api/blocks/by/$other/exists');
    }

    return false;
  }
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}