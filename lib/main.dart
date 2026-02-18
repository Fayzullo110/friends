import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/auth/auth_gate.dart';
import 'l10n/app_localizations.dart';
import 'services/auth_service.dart';

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
    final ColorScheme lightScheme = ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.light,
    );
    const ColorScheme darkScheme = ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.black,
      secondary: Colors.white70,
      onSecondary: Colors.black,
      surface: Color(0xFF121212),
      onSurface: Colors.white,
      background: Colors.black,
      onBackground: Colors.white,
      error: Color(0xFFCF6679),
      onError: Colors.black,
    );

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
      theme: ThemeData(
        colorScheme: lightScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const AuthGate(),
    );
  }
}
