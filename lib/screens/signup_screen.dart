import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:phys_ed/providers/image_upload_provider.dart';
import 'package:phys_ed/providers/auth_provider.dart';
import 'package:phys_ed/screens/onboarding_screen.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  static const Color lnuNavy = Color(0xFF002147);
  static const Color academicGray = Color(0xFFF0F4F8);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- NEW: GOOGLE SIGN UP LOGIC ---
  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);
    try {
      final authController = ref.read(authControllerProvider);
      final authRepository = ref.read(authRepositoryProvider);

      // 1. Authenticate (Forces account picker via updated provider)
      final userCredential = await authController.signInWithGoogle();

      if (userCredential != null && mounted) {
        // 2. Check if user already exists in Firestore
        final exists = await authRepository.doesUserExist(userCredential.user!.uid);

        if (!exists) {
          // 3. New User: Route to Onboarding
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        } else {
          // Existing User: AuthWrapper in main.dart will handle the dashboard routing
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-Up failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- STANDARD EMAIL SIGN UP ---
  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // For email signup, we still need onboarding details
      // OR we route them to OnboardingScreen after account creation.
      // Let's route to Onboarding for a unified experience.
      final userCredential = await ref.read(authControllerProvider).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: 'student', // Default or add a toggle
        section: '',
        yearLevel: '',
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: academicGray,
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: lnuNavy),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school_outlined, size: 80, color: lnuNavy),
                const SizedBox(height: 24),
                const Text(
                  "Join the LNU PE Portal",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: lnuNavy),
                ),
                const SizedBox(height: 32),

                // GOOGLE SIGN UP BUTTON
                _buildGoogleButton(),

                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("OR USE EMAIL", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                _buildTextField(_emailController, "Gmail Address", Icons.email_outlined),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, "Password", Icons.lock_outline, obscure: true),
                const SizedBox(height: 24),

                _buildPrimaryButton("CREATE WITH EMAIL", _handleEmailSignUp),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Already have an account? Sign in", style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() => OutlinedButton.icon(
    onPressed: _isLoading ? null : _handleGoogleSignUp,
    icon: Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/512px-Google_%22G%22_Logo.svg.png',
      height: 24,
    ),
    label: const Text(
      "Sign Up with Google",
      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
    ),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Colors.black12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) =>
      TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: lnuNavy),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
        ),
      );

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) => SizedBox(
    height: 55,
    child: ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: lnuNavy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    ),
  );
}