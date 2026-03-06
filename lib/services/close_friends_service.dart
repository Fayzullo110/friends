import 'auth_service.dart';

class CloseFriendsService {
  CloseFriendsService._();

  static final CloseFriendsService instance = CloseFriendsService._();

  Future<List<String>> listOnce() async {
    final list = await AuthService.instance.api.getList('/api/close-friends');
    return list.map((e) => e.toString()).toList();
  }

  Future<void> add({required String userId}) async {
    final id = int.parse(userId);
    await AuthService.instance.api.postNoContent('/api/close-friends/$id');
  }

  Future<void> remove({required String userId}) async {
    final id = int.parse(userId);
    await AuthService.instance.api.deleteNoContent('/api/close-friends/$id');
  }
}
