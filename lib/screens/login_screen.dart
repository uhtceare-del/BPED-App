import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'signup_screen.dart';
import 'student_dashboard.dart';
import 'instructor_dashboard.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // LNU Identity Colors
  static const Color lnuNavy = Color(0xFF002147);
  static const Color lnuMaroon = Color(0xFF800000);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // LOGIC PRESERVED: Google Sign-In handler
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authControllerProvider).signInWithGoogle();

      if (result == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Sign-In failed or was cancelled")),
        );
      }
      // No Navigator.push needed! AuthWrapper in main.dart handles the switch.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // LOGIC PRESERVED: Email/Password login handler
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userCredential = await ref.read(authControllerProvider).signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!userCredential.user!.emailVerified) {
        await ref.read(authControllerProvider).signOut();
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showUnverifiedDialog(userCredential.user!);
        return;
      }

      final userDoc = await ref.read(firestoreProvider)
          .collection('users').doc(userCredential.user!.uid).get();

      final role = userDoc.data()?['role'] as String? ?? 'student';

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'instructor' ? const InstructorDashboard() : const StudentDashboard(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: $e"), backgroundColor: lnuMaroon),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _showUnverifiedDialog(user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Email Not Verified", style: TextStyle(color: lnuMaroon, fontWeight: FontWeight.bold)),
        content: const Text("Check your Gmail inbox and click the verification link before logging in."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: lnuNavy),
            onPressed: () async {
              await ref.read(authControllerProvider).resendVerificationEmail(user);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Resend Link"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light academic grey background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LNU LOGO SECTION
                  Image.network(
                    'https://www.lnu.edu.ph/wp-content/uploads/2021/04/LNU-Logo-1.png',
                    height: 120,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.school, size: 80, color: lnuNavy),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "BPED MANAGEMENT SYSTEM",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: lnuNavy,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const Text(
                    "Leyte Normal University",
                    style: TextStyle(fontSize: 14, color: lnuMaroon, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 48),

                  // INPUT FIELDS
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Gmail Address",
                      prefixIcon: const Icon(Icons.email_outlined, color: lnuNavy),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: lnuNavy, width: 2),
                      ),
                    ),
                    validator: (v) => !RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(v ?? '')
                        ? 'Must be a valid @gmail.com' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline, color: lnuNavy),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: lnuNavy, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Password required' : null,
                  ),
                  const SizedBox(height: 32),

                  // SIGN IN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lnuNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SIGN IN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GOOGLE BUTTON (Fixed with Cool Logo)
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    label: const Text(
                      "Continue with Google",
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.grey, width: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SIGNUP LINK
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        ),
                        child: const Text(
                          "Create Account",
                          style: TextStyle(color: lnuMaroon, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}