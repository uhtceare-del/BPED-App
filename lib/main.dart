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
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox('downloadsBox');

  runApp(const ProviderScope(child: MyApp()));
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
        primaryColor: const Color(0xFF002147),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF002147),
          primary: const Color(0xFF002147),
        ),
      ),
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
            // No Firestore document yet → onboarding
            if (appUser == null) return const OnboardingScreen();

            // Onboarding flag not set → onboarding
            if (!appUser.onboardingCompleted) return const OnboardingScreen();

            // Role must be set → onboarding
            if (appUser.role.isEmpty) return const OnboardingScreen();

            // Instructors do NOT have section/yearLevel — skip that check for them
            if (appUser.role == 'instructor') {
              return const InstructorDashboard();
            }

            // Students must have section + yearLevel filled in
            final studentIncomplete =
                (appUser.section?.isEmpty ?? true) ||
                (appUser.yearLevel?.isEmpty ?? true);

            if (studentIncomplete) return const OnboardingScreen();

            return const StudentDashboard();
          },
          loading: () => const LoadingScaffold(),
          error: (e, _) => ErrorScaffold(message: 'Profile Error: $e'),
        );
      },
      loading: () => const LoadingScaffold(),
      error: (e, _) => ErrorScaffold(message: 'Auth Error: $e'),
    );
  }
}

class LoadingScaffold extends StatelessWidget {
  const LoadingScaffold({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFF002147))),
      );
}

class ErrorScaffold extends StatelessWidget {
  final String message;
  const ErrorScaffold({super.key, required this.message});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(message)));
}
