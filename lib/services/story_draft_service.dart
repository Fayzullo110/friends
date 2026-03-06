import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoryDraftService {
  StoryDraftService._();

  static final StoryDraftService instance = StoryDraftService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _key = 'story_draft_v1';

  Future<Map<String, dynamic>?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  }

  Future<void> save(Map<String, dynamic> draft) async {
    await _storage.write(key: _key, value: jsonEncode(draft));
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
