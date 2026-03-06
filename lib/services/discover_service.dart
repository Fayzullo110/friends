import '../models/app_user.dart';
import 'auth_service.dart';

class DiscoverService {
  DiscoverService._();

  static final DiscoverService instance = DiscoverService._();

  Future<List<AppUser>> getSuggestedUsers({int limit = 50}) async {
    final safeLimit = limit.clamp(1, 100);
    final rows = await AuthService.instance.api.getListOfMaps(
      '/api/users/suggested?limit=$safeLimit',
    );
    return rows.map(AppUser.fromJson).toList();
  }
}
