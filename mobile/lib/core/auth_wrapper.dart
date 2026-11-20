import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';

/// AuthWrapper handles route protection at the app root level.
///
/// It checks the authentication state and shows the appropriate screen:
/// - Authenticated → HomeScreen
/// - Unauthenticated → LoginScreen
/// - Loading/Initial → LoginScreen (AuthProvider will redirect after check)
///
/// This prevents unauthenticated access to protected routes while keeping
/// the router simple and focused on page transitions.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check auth status on first load — this reads stored token/user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthProvider>().checkAuthStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthProvider>().state;

    // Show loading indicator while checking auth status
    if (authState == AuthState.loading || authState == AuthState.initial) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Route guard: redirect to login if not authenticated
    if (authState == AuthState.authenticated) {
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}
