import 'auth_service.dart';

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) async {
    final type = targetType.trim();
    final id = int.parse(targetId);
    final r = reason.trim();
    if (type.isEmpty || r.isEmpty) return;

    await AuthService.instance.api.postNoContent(
      '/api/reports',
      body: {
        'targetType': type,
        'targetId': id,
        'reason': r,
        'details': details,
      },
    );
  }
}
