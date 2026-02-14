// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'Doʻstlar';

  @override
  String get circles => 'Hikoyalar';

  @override
  String get searchUsersTitle => 'Foydalanuvchilarni qidirish';

  @override
  String get searchByUsername => 'Username bo‘yicha qidirish';

  @override
  String get loading => 'Yuklanmoqda…';

  @override
  String get noUsers => 'Foydalanuvchi topilmadi';

  @override
  String searchFailed(Object error) {
    return 'Qidiruv xatosi: $error';
  }
}
