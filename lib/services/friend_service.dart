import 'dart:async';

import 'auth_service.dart';

class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUsername;
  final DateTime createdAt;
  final String status; // pending, accepted, rejected

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUsername,
    required this.createdAt,
    required this.status,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> data) {
    return FriendRequest(
      id: data['id'].toString(),
      fromUserId: data['fromUserId'].toString(),
      toUserId: data['toUserId'].toString(),
      fromUsername: data['fromUsername'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
        isUtc: false,
      ),
      status: data['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUsername': fromUsername,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status,
    };
  }
}

class FriendService {
  FriendService._();

  static final FriendService instance = FriendService._();

  Future<void> sendRequest({
    required String fromUserId,
    required String fromUsername,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) return;
    final target = int.parse(toUserId);
    await AuthService.instance.api.postNoContent('/api/friends/requests/$target');
  }

  Stream<List<FriendRequest>> watchIncoming({required String uid}) {
    final controller = StreamController<List<FriendRequest>>();
    List<FriendRequest>? last;

    Future<void> tick() async {
      try {
        final rows = await AuthService.instance.api
            .getListOfMaps('/api/friends/requests/incoming');
        final next = rows.map(FriendRequest.fromJson).toList();
        if (last == null || !_reqEquals(last!, next)) {
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

  Future<void> acceptRequest(String requestId) async {
    final id = int.parse(requestId);
    await AuthService.instance.api
        .postNoContent('/api/friends/requests/$id/accept');
  }

  Future<void> rejectRequest(String requestId) async {
    final id = int.parse(requestId);
    await AuthService.instance.api
        .postNoContent('/api/friends/requests/$id/reject');
  }

  Stream<List<String>> watchFriends({required String uid}) {
    final controller = StreamController<List<String>>();
    List<String>? last;

    Future<void> tick() async {
      try {
        final list = await AuthService.instance.api.getList('/api/friends');
        final next = list.map((e) => e.toString()).toList()..sort();
        if (last == null || !_listEquals(last!, next)) {
          last = next;
          controller.add(next);
        }
      } catch (_) {
        // swallow
      }
    }

    tick();
    final timer = Timer.periodic(const Duration(seconds: 15), (_) => tick());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }
}

bool _reqEquals(List<FriendRequest> a, List<FriendRequest> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final ra = a[i];
    final rb = b[i];
    if (ra.id != rb.id) return false;
    if (ra.status != rb.status) return false;
  }
  return true;
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
