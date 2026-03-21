import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'student_dashboard.dart'; 
import 'instructor_dashboard.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();

  String? selectedRole;
  String? selectedYear;
  String? selectedSection;

  // NEW: Loading state variable
  bool _isSaving = false;

  final Map<String, List<String>> yearToSections = {
    '1': ['PE-11', 'PE-12', 'PE-13', 'PE-14'],
    '2': ['PE-21', 'PE-22', 'PE-23', 'PE-24'],
    '3': ['PE-31', 'PE-32', 'PE-33', 'PE-34'],
    '4': ['PE-41', 'PE-42', 'PE-43', 'PE-44'],
  };

  static const Color lnuNavy = Color(0xFF002147);

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile Setup", style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome to LNU PE Portal!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: lnuNavy)),
              const SizedBox(height: 8),
              const Text("Final step! Tell us who you are.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),

              // Full Name
              TextFormField(
                controller: nameController,
                enabled: !_isSaving, // Disable input while saving
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => (val == null || val.isEmpty) ? "Enter your name" : null,
              ),
              const SizedBox(height: 20),

              // Role Dropdown
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: "I am a...",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'student', child: Text("Student")),
                  DropdownMenuItem(value: 'instructor', child: Text("Instructor")),
                ],
                onChanged: _isSaving ? null : (val) { // Disable if saving
                  setState(() {
                    selectedRole = val;
                    selectedYear = null;
                    selectedSection = null;
                  });
                },
                validator: (val) => val == null ? "Please select your role" : null,
              ),

              if (selectedRole == 'student') ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedYear,
                  decoration: const InputDecoration(labelText: "Year Level", border: OutlineInputBorder(), prefixIcon: Icon(Icons.trending_up)),
                  items: yearToSections.keys.map((year) => DropdownMenuItem(value: year, child: Text("Year $year"))).toList(),
                  onChanged: _isSaving ? null : (val) {
                    setState(() {
                      selectedYear = val;
                      selectedSection = null;
                    });
                  },
                  validator: (val) => val == null ? "Select year level" : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedSection,
                  disabledHint: const Text("Select Year Level first"),
                  decoration: const InputDecoration(labelText: "Section", border: OutlineInputBorder(), prefixIcon: Icon(Icons.class_outlined)),
                  items: selectedYear == null
                      ? []
                      : yearToSections[selectedYear]!.map((sec) => DropdownMenuItem(value: sec, child: Text(sec))).toList(),
                  onChanged: _isSaving ? null : (val) => setState(() => selectedSection = val),
                  validator: (val) => val == null ? "Select section" : null,
                ),
              ],

              const SizedBox(height: 40),

              // UPDATED BUTTON WITH LOADING FEEDBACK
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lnuNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _saveProfile, // Disable click if saving
                  child: _isSaving
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                      : const Text("COMPLETE SETUP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        final user = ref.read(authControllerProvider).currentUser;
        if (user == null) return;

        await ref.read(authRepositoryProvider).completeOnboarding(
          uid: user.uid,
          fullName: nameController.text.trim(),
          role: selectedRole!,
          yearLevel: selectedRole == 'student' ? selectedYear! : '',
          section: selectedRole == 'student' ? selectedSection! : '',
        );

        if (mounted) {
          // --- ROLE-BASED ROUTING LOGIC ---
          Widget nextScreen;
          if (selectedRole == 'instructor') {
            nextScreen = const InstructorDashboard();
          } else {
            nextScreen = const StudentDashboard();
          }

          // Use pushAndRemoveUntil to prevent user from going back to Onboarding
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => nextScreen),
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}