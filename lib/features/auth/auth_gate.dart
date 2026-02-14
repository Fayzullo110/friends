import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../shell/friends_shell.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: AuthService.instance.userChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const _AuthSwitcher();
        }

        return const FriendsShell();
      },
    );
  }
}

class _AuthSwitcher extends StatefulWidget {
  const _AuthSwitcher();

  @override
  State<_AuthSwitcher> createState() => _AuthSwitcherState();
}

class _AuthSwitcherState extends State<_AuthSwitcher> {
  bool _showLogin = true;

  void _toggle() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginScreen(onSwitchToSignUp: _toggle);
    }
    return SignUpScreen(onSwitchToLogin: _toggle);
  }
}
