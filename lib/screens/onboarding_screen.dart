import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();

  String? selectedYear;
  String? selectedSection;

  // Your specific logic: Year level maps to its 4 sections
  final Map<String, List<String>> yearToSections = {
    '1': ['PE-11', 'PE-12', 'PE-13', 'PE-14'],
    '2': ['PE-21', 'PE-22', 'PE-23', 'PE-24'],
    '3': ['PE-31', 'PE-32', 'PE-33', 'PE-34'],
    '4': ['PE-41', 'PE-42', 'PE-43', 'PE-44'],
  };

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Student Profile", style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
              const Text("Please complete your details to proceed.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),

              // Full Name Field
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => val!.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 20),

              // Year Level Dropdown
              DropdownButtonFormField<String>(
                value: selectedYear,
                decoration: const InputDecoration(labelText: "Year Level", border: OutlineInputBorder(), prefixIcon: Icon(Icons.trending_up)),
                items: yearToSections.keys.map((year) => DropdownMenuItem(value: year, child: Text("Year $year"))).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedYear = val;
                    selectedSection = null; // Reset section when year changes
                  });
                },
                validator: (val) => val == null ? "Select year level" : null,
              ),
              const SizedBox(height: 20),

              // Section Dropdown (Enabled only if Year is selected)
              DropdownButtonFormField<String>(
                value: selectedSection,
                disabledHint: const Text("Select Year Level first"),
                decoration: const InputDecoration(labelText: "Section", border: OutlineInputBorder(), prefixIcon: Icon(Icons.class_outlined)),
                items: selectedYear == null
                    ? []
                    : yearToSections[selectedYear]!.map((sec) => DropdownMenuItem(value: sec, child: Text(sec))).toList(),
                onChanged: (val) => setState(() => selectedSection = val),
                validator: (val) => val == null ? "Select section" : null,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: lnuNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _saveProfile,
                  child: const Text("FINISH SIGN UP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
      final user = ref.read(authControllerProvider).currentUser;

      await ref.read(authRepositoryProvider).completeOnboarding(
        uid: user!.uid,
        fullName: nameController.text,
        role: 'student', // Default for this screen
        yearLevel: selectedYear!,
        section: selectedSection!,
      );

      // Once saved, your main.dart auth listener will automatically
      // see the new user document and send them to the Student Dashboard.
      if (mounted) {
        Navigator.of(context).pop(); // Or pushReplacement to Dashboard
      }
    }
  }
}