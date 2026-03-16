import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'student_dashboard.dart';
import 'instructor_dashboard.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // Not signed in → show login
          return const LoginScreen();
        }

        // User signed in → check role
        final roleAsync = ref.watch(userRoleProvider);

        return roleAsync.when(
          data: (role) {
            switch (role) {
              case 'student':
                return const StudentDashboard();
              case 'instructor':
                return const InstructorDashboard();
              default:
                return const Scaffold(
                  body: Center(child: Text('Role not assigned')),
                );
            }
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            body: Center(child: Text('Error loading role: $e')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text("Auth error: $e")),
      ),
    );
  }
}