import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_gate.dart';
import 'l10n/app_localizations.dart';
import 'services/auth_service.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize AuthService with backend URL
  AuthService.instance.init(baseUrl: 'http://localhost:8080');
  // Try to restore session from stored JWT
  await AuthService.instance.initFromStoredToken();
  runApp(const FriendsApp());
}

class FriendsApp extends StatelessWidget {
  const FriendsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeController(authService: AuthService.instance),
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('uz'),
            ],
            themeMode: ThemeMode.system,
            theme: themeController.lightTheme,
            darkTheme: themeController.darkTheme,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
