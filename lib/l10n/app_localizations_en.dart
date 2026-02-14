// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Friends';

  @override
  String get circles => 'Circles';

  @override
  String get searchUsersTitle => 'Search users';

  @override
  String get searchByUsername => 'Search by username';

  @override
  String get loading => 'Loading…';

  @override
  String get noUsers => 'No users';

  @override
  String searchFailed(Object error) {
    return 'Search failed: $error';
  }
}
