import 'auth_service.dart';

class AdminUserService {
  AdminUserService._();

  static final AdminUserService instance = AdminUserService._();

  Future<void> updateBadge({
    required String userId,
    bool? isOfficial,
    String? badgeType,
  }) async {
    final id = int.parse(userId);
    await AuthService.instance.api.patchNoContent(
      '/api/admin/users/$id/badge',
      body: {
        'isOfficial': isOfficial,
        'badgeType': badgeType,
      },
    );
  }
}
