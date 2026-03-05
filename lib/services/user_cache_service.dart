import 'dart:async';

import '../models/app_user.dart';
import 'auth_service.dart';

class UserCacheService {
  UserCacheService._();

  static final UserCacheService instance = UserCacheService._();

  final Map<String, AppUser> _cache = <String, AppUser>{};
  final Map<String, Future<AppUser>> _inFlight = <String, Future<AppUser>>{};

  final Set<String> _pending = <String>{};
  final Map<String, List<Completer<AppUser>>> _waitersById =
      <String, List<Completer<AppUser>>>{};
  Timer? _batchTimer;

  final StreamController<String> _updates = StreamController<String>.broadcast();

  Stream<String> get updates => _updates.stream;

  AppUser? peek(String userId) {
    return _cache[userId.trim()];
  }

  Future<AppUser> get(String userId) {
    final key = userId.trim();
    if (key.isEmpty) {
      return Future.value(AppUser(id: userId, email: '', username: ''));
    }

    final cached = _cache[key];
    if (cached != null) return Future.value(cached);

    final existing = _inFlight[key];
    if (existing != null) return existing;

    final completer = Completer<AppUser>();
    (_waitersById[key] ??= <Completer<AppUser>>[]).add(completer);
    _pending.add(key);

    // Mark as in-flight so concurrent callers are deduped.
    _inFlight[key] = completer.future;

    _batchTimer ??= Timer(const Duration(milliseconds: 20), _flushBatch);
    return completer.future;
  }

  Future<void> _flushBatch() async {
    _batchTimer?.cancel();
    _batchTimer = null;

    if (_pending.isEmpty) return;

    // Firestore backend limits sometimes appear elsewhere; keep this safe.
    final ids = _pending.take(30).toList();
    _pending.removeAll(ids);

    try {
      final joined = ids.join(',');
      final rows = await AuthService.instance.api.getListOfMaps(
        '/api/users?ids=$joined',
      );

      final users = rows.map(AppUser.fromJson).toList();
      final byId = <String, AppUser>{
        for (final u in users) u.id: u,
      };

      for (final id in ids) {
        final u = byId[id] ?? AppUser(id: id, email: '', username: '');
        _cache[id] = u;
        _inFlight.remove(id);

        final waiters = _waitersById.remove(id) ?? const <Completer<AppUser>>[];
        for (final c in waiters) {
          if (!c.isCompleted) c.complete(u);
        }
        _updates.add(id);
      }
    } catch (_) {
      for (final id in ids) {
        _inFlight.remove(id);
        final u = AppUser(id: id, email: '', username: '');
        final waiters = _waitersById.remove(id) ?? const <Completer<AppUser>>[];
        for (final c in waiters) {
          if (!c.isCompleted) c.complete(u);
        }
        _updates.add(id);
      }
    } finally {
      // If more IDs arrived while we were fetching, flush again quickly.
      if (_pending.isNotEmpty) {
        _batchTimer ??= Timer(const Duration(milliseconds: 10), _flushBatch);
      }
    }
  }

  void dispose() {
    _batchTimer?.cancel();
    _updates.close();
  }
}
