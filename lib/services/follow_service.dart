import 'block_service.dart';
import 'auth_service.dart';

class FollowService {
  FollowService._();

  static final FollowService instance = FollowService._();

  Stream<List<String>> watchFollowers({required String uid}) {
    return _pollList(() => getFollowersOnce(uid: uid));
  }

  Stream<List<String>> watchFollowing({required String uid}) {
    return _pollList(() => getFollowingOnce(uid: uid));
  }

  Stream<List<String>> watchIncomingRequests({required String uid}) {
    return _pollList(() => getIncomingRequestsOnce(uid: uid));
  }

  Stream<List<String>> watchOutgoingRequests({required String uid}) {
    return _pollList(() => getOutgoingRequestsOnce(uid: uid));
  }

  Stream<List<String>> _pollList(Future<List<String>> Function() loader) async* {
    List<String>? last;
    while (true) {
      final next = await loader();
      next.sort();
      if (last == null || !_listEquals(last, next)) {
        last = next;
        yield next;
      }
      await Future<void>.delayed(const Duration(seconds: 10));
    }
  }

  Future<List<String>> getFollowersOnce({required String uid}) async {
    final list = await AuthService.instance.api.getList('/api/follows/followers');
    return list.map((e) => e.toString()).toList();
  }

  Future<List<String>> getFollowingOnce({required String uid}) async {
    final list = await AuthService.instance.api.getList('/api/follows/following');
    return list.map((e) => e.toString()).toList();
  }

  Future<List<String>> getIncomingRequestsOnce({required String uid}) async {
    final list = await AuthService.instance.api.getList('/api/follows/requests/incoming');
    return list.map((e) => e.toString()).toList();
  }

  Future<List<String>> getOutgoingRequestsOnce({required String uid}) async {
    final list = await AuthService.instance.api.getList('/api/follows/requests/outgoing');
    return list.map((e) => e.toString()).toList();
  }

  Future<void> follow({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) return;

    // Do not allow follow if there is a block in either direction.
    final hasBlocked = await BlockService.instance.isBlocked(
      fromUserId: fromUserId,
      toUserId: toUserId,
    );
    final isBlockedByOther = await BlockService.instance.isBlocked(
      fromUserId: toUserId,
      toUserId: fromUserId,
    );

    if (hasBlocked || isBlockedByOther) {
      throw Exception('blocked');
    }

    final target = int.parse(toUserId);
    await AuthService.instance.api.postNoContent('/api/follows/$target');
  }

  Future<void> unfollow({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) return;

    final target = int.parse(toUserId);
    await AuthService.instance.api.deleteNoContent('/api/follows/$target');
  }

  Future<void> acceptRequest({required String followerId}) async {
    final id = int.parse(followerId);
    await AuthService.instance.api.postNoContent('/api/follows/requests/$id/accept');
  }

  Future<void> declineRequest({required String followerId}) async {
    final id = int.parse(followerId);
    await AuthService.instance.api.deleteNoContent('/api/follows/requests/$id');
  }

  Future<void> cancelRequest({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) return;
    final target = int.parse(toUserId);
    await AuthService.instance.api.deleteNoContent('/api/follows/requests/$target');
  }

  Stream<bool> watchIsFollowing({
    required String fromUserId,
    required String toUserId,
  }) {
    if (fromUserId.isEmpty || toUserId.isEmpty) {
      return Stream.value(false);
    }
    return _pollBool(() => isFollowing(fromUserId: fromUserId, toUserId: toUserId));
  }

  Stream<bool> watchIsRequested({
    required String fromUserId,
    required String toUserId,
  }) {
    if (fromUserId.isEmpty || toUserId.isEmpty) {
      return Stream.value(false);
    }
    return _pollBool(() => isRequested(fromUserId: fromUserId, toUserId: toUserId));
  }

  Stream<bool> _pollBool(Future<bool> Function() loader) async* {
    bool? last;
    while (true) {
      final next = await loader();
      if (last == null || last != next) {
        last = next;
        yield next;
      }
      await Future<void>.delayed(const Duration(seconds: 10));
    }
  }

  Future<bool> isFollowing({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) return false;
    final target = int.parse(toUserId);
    return AuthService.instance.api.getBool('/api/follows/$target/exists');
  }

  Future<bool> isRequested({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) return false;
    final target = int.parse(toUserId);
    return AuthService.instance.api.getBool('/api/follows/$target/requested');
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
