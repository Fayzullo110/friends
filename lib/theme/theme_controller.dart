import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'app_themes.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({required AuthService authService}) : _authService = authService {
    _sub = _authService.userChanges.listen(_onUser);
    _onUser(_authService.currentUser);
  }

  final AuthService _authService;
  StreamSubscription<AppUser?>? _sub;

  String? _themeKey;
  int? _themeSeedColor;

  String? get themeKey => _themeKey;
  int? get themeSeedColor => _themeSeedColor;

  Color get seedColor => AppThemes.seedFor(
        themeKey: _themeKey,
        themeSeedColor: _themeSeedColor,
      );

  ThemeData get lightTheme => AppThemes.light(seedColor: seedColor);
  ThemeData get darkTheme => AppThemes.dark(seedColor: seedColor);

  void _onUser(AppUser? user) {
    final nextKey = user?.themeKey;
    final nextSeed = user?.themeSeedColor;

    if (nextKey == _themeKey && nextSeed == _themeSeedColor) return;
    _themeKey = nextKey;
    _themeSeedColor = nextSeed;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
