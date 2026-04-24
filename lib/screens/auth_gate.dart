import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const AuthGate({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {

        final session =
            Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return LoginScreen(
            onLoginSuccess: () {},
          );
        }

        return HomeScreen(
          onToggleTheme: onToggleTheme,
        );
      },
    );
  }
}