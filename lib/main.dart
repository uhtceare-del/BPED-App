import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/instructor_dashboard.dart';

// Providers
import 'providers/auth_provider.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Initialize Hive for Offline capabilities (Reviewers/Downloads)
  await Hive.initFlutter();
  await Hive.openBox('downloadsBox');

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PhysEdLearn',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF002147), // LNU Navy
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF002147),
          primary: const Color(0xFF002147),
        ),
      ),
      // The AuthWrapper determines the starting screen dynamically
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginScreen();

        return ref.watch(currentUserProvider).when(
          data: (appUser) {
            // 1. If the document doesn't exist at all
            if (appUser == null) {
              return const OnboardingScreen();
            }

            // 2. FIXED: Safely check if fields are empty
            // If section or yearLevel is null OR empty, go to Onboarding
            final bool isIncomplete = (appUser.section?.isEmpty ?? true) ||
                (appUser.yearLevel?.isEmpty ?? true);

            if (isIncomplete) {
              return const OnboardingScreen();
            }

            // 3. Everything is complete!
            return appUser.role == 'instructor'
                ? const InstructorDashboard()
                : const StudentDashboard();
          },
          loading: () => const LoadingScaffold(),
          error: (e, _) => ErrorScaffold(message: "Profile Error: $e"),
        );
      },
      loading: () => const LoadingScaffold(),
      error: (e, _) => ErrorScaffold(message: "Auth Error: $e"),
    );
  }
}

// Simple helper for the loading state
class LoadingScaffold extends StatelessWidget {
  const LoadingScaffold({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF002147)),
      ),
    );
  }
}

// Simple helper for error state
class ErrorScaffold extends StatelessWidget {
  final String message;
  const ErrorScaffold({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(message)),
    );
  }
}