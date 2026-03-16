import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// Relative imports
import '../providers/image_upload_provider.dart';
import '../providers/auth_provider.dart';
import '../controllers/auth_controller.dart';
import 'student_dashboard.dart';
import 'instructor_dashboard.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sectionController = TextEditingController();
  final _yearLevelController = TextEditingController();

  File? _mobileImageFile;
  Uint8List? _webImageBytes;
  String? _uploadedImageUrl;
  bool _isPickingImage = false;
  String _selectedRole = 'student';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _sectionController.dispose();
    _yearLevelController.dispose();
    super.dispose();
  }

  bool get isBusy => _isPickingImage || ref.watch(imageUploadProvider).isLoading;

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        obscureText: obscure,
        validator: validator,
      );

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _mobileImageFile = null;
          _uploadedImageUrl = null;
        });
      } else {
        setState(() {
          _mobileImageFile = File(picked.path);
          _webImageBytes = null;
          _uploadedImageUrl = null;
        });
      }

      ref.read(imageUploadProvider.notifier).reset();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to pick image: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<String?> _uploadAvatar() async {
    if ((kIsWeb && _webImageBytes != null)) {
      return await ref.read(imageUploadProvider.notifier)
          .uploadBytes(_webImageBytes!, filename: 'avatar_${_emailController.text.split('@')[0]}.jpg');
    } else if (!kIsWeb && _mobileImageFile != null) {
      return await ref.read(imageUploadProvider.notifier).upload(_mobileImageFile!);
    }
    return null;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = ref.read(authControllerProvider);

    try {
      // Sign up user first without avatar
      final userCredential = await ref.read(authControllerProvider).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        avatarUrl: null,
        section: _selectedRole == 'student' ? _sectionController.text.trim() : null,
        yearLevel: _selectedRole == 'student' ? int.tryParse(_yearLevelController.text.trim()) : null,
      );

      // Upload avatar if any
      String? avatarUrl;
      if (_mobileImageFile != null || _webImageBytes != null) {
        avatarUrl = await _uploadAvatar();
      }

      // Update Firestore document with avatar
      if (avatarUrl != null) {
        await authController.updateUserAvatar(
          uid: userCredential.user!.uid,
          avatarUrl: avatarUrl,
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _selectedRole == 'student'
              ? const StudentDashboard()
              : const InstructorDashboard(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sign up failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ImageProvider? get _avatarImage {
    if (_uploadedImageUrl != null) return NetworkImage(_uploadedImageUrl!);
    if (kIsWeb && _webImageBytes != null) return MemoryImage(_webImageBytes!);
    if (!kIsWeb && _mobileImageFile != null) return FileImage(_mobileImageFile!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(imageUploadProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Create Account"), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: GestureDetector(
                    onTap: isBusy ? null : _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _avatarImage,
                          child: _avatarImage == null
                              ? const Icon(Icons.add_a_photo, size: 48, color: Colors.white70)
                              : null,
                        ),
                        if (isBusy)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildField(
                  controller: _emailController,
                  label: 'Email',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildField(
                  controller: _passwordController,
                  label: 'Password',
                  obscure: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Password is required';
                    if (v.trim().length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Select Role', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'instructor', child: Text('Instructor')),
                  ],
                  onChanged: isBusy ? null : (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                if (_selectedRole == 'student') ...[
                  const SizedBox(height: 20),
                  _buildField(controller: _sectionController, label: 'Section'),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _yearLevelController,
                    label: 'Year Level',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: isBusy ? null : _signUp,
                  icon: isBusy
                      ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                      : const Icon(Icons.person_add),
                  label: Text(isBusy ? 'Creating...' : 'Create Account'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: isBusy ? null : () => Navigator.pop(context),
                  child: const Text("Already have an account? Sign in"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}