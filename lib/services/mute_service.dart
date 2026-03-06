import 'dart:async';

import 'auth_service.dart';

class MuteService {
  MuteService._();
  static final MuteService instance = MuteService._();

  Stream<List<String>> watchMuted({required String uid}) async* {
    List<String>? last;
    while (true) {
      final next = await getMutedOnce(uid: uid);
      next.sort();
      if (last == null || !_listEquals(last, next)) {
        last = next;
        yield next;
      }
      await Future<void>.delayed(const Duration(seconds: 10));
    }
  }

  Future<List<String>> getMutedOnce({required String uid}) async {
    final list = await AuthService.instance.api.getList('/api/mutes');
    return list.map((e) => e.toString()).toList();
  }

  Future<void> mute({required String fromUserId, required String toUserId}) async {
    if (fromUserId == toUserId) return;
    final target = int.parse(toUserId);
    await AuthService.instance.api.postNoContent('/api/mutes/$target');
  }

  Future<void> unmute({required String fromUserId, required String toUserId}) async {
    final target = int.parse(toUserId);
    await AuthService.instance.api.deleteNoContent('/api/mutes/$target');
  }

  Future<bool> isMuted({required String toUserId}) async {
    final me = AuthService.instance.currentUser;
    if (me == null) return false;
    final target = int.parse(toUserId);
    return await AuthService.instance.api.getBool('/api/mutes/$target/exists');
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
