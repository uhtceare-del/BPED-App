import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/class_provider.dart';
import '../providers/auth_provider.dart';
import '../models/class_model.dart';

// --- THE FIX: SECURED ROLE-BASED CLASS STREAM ---
final securedClassesStreamProvider =
    StreamProvider.autoDispose<List<ClassModel>>((ref) {
      final user = ref.watch(currentUserProvider).value;

      if (user == null) {
        debugPrint("DEBUG: Provider - No user logged in.");
        return Stream.value([]);
      }

      final isInstructor = user.role?.toLowerCase() == 'instructor';
      final collection = FirebaseFirestore.instance.collection('classes');

      if (isInstructor) {
        debugPrint(
          "DEBUG: Provider - Fetching classes for Instructor: ${user.uid}",
        );
        return collection
            .where('instructorId', isEqualTo: user.uid)
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => ClassModel.fromFirestore(doc))
                  .toList(),
            );
      } else {
        debugPrint(
          "DEBUG: Provider - Fetching classes for Student: ${user.uid}",
        );
        return collection
            .where('enrolledStudents', arrayContains: user.uid)
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => ClassModel.fromFirestore(doc))
                  .toList(),
            );
      }
    });

class ClassScreen extends ConsumerWidget {
  const ClassScreen({super.key});

  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(securedClassesStreamProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final isInstructor =
        currentUserAsync.value?.role?.toLowerCase() == 'instructor';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Classes & Sections',
          style: TextStyle(fontWeight: FontWeight.bold, color: lnuNavy),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: classesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            return Center(
              child: Text(
                isInstructor
                    ? "No classes created yet."
                    : "You are not enrolled in any classes.",
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final section = classes[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: lnuNavy.withOpacity(0.1),
                    child: const Icon(Icons.groups, color: lnuNavy),
                  ),
                  title: Text(
                    section.className,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: lnuNavy,
                    ),
                  ),
                  subtitle: Text("${section.subject} • ${section.schedule}"),
                  trailing: isInstructor
                      ? const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        )
                      : null,
                  onTap: isInstructor
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ClassDetailScreen(classData: section),
                            ),
                          );
                        }
                      : null,
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: lnuNavy)),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: isInstructor
          ? FloatingActionButton.extended(
              backgroundColor: lnuNavy,
              onPressed: () => _showAddClassDialog(context, ref),
              label: const Text(
                "Add Section",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    final schedController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Create New Section",
          style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Class Name"),
            ),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: "Subject"),
            ),
            TextField(
              controller: schedController,
              decoration: const InputDecoration(labelText: "Schedule"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: lnuNavy),
            onPressed: () async {
              final user = ref.read(currentUserProvider).value;
              final newClass = ClassModel(
                id: '',
                className: nameController.text.trim(),
                subject: subjectController.text.trim(),
                schedule: schedController.text.trim(),
                instructorId: user?.uid ?? 'unknown',
                enrolledStudents: [],
              );
              await ref.read(classRepositoryProvider).createClass(newClass);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Create", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class ClassDetailScreen extends ConsumerStatefulWidget {
  final ClassModel classData;
  const ClassDetailScreen({super.key, required this.classData});

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen> {
  static const Color lnuNavy = Color(0xFF002147);
  final TextEditingController _emailController = TextEditingController();
  bool _isEnrolling = false;

  Future<void> _sendEnrollmentEmail({
    required String studentEmail,
    required String studentName,
    required String className,
    required String instructorName,
  }) async {
    // RENAME THESE TO YOUR ACTUAL EMAILJS KEYS
    const serviceId = 'YOUR_EMAILJS_SERVICE_ID';
    const templateId = 'YOUR_EMAILJS_TEMPLATE_ID';
    const userId = 'YOUR_EMAILJS_PUBLIC_KEY';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'to_email': studentEmail,
            'to_name': studentName,
            'class_name': className,
            'instructor_name': instructorName,
          },
        }),
      );
      debugPrint("DEBUG: Email response status: ${response.statusCode}");
    } catch (e) {
      debugPrint("DEBUG: Email error: $e");
    }
  }

  void _showEditStudentDialog(
    String studentId,
    String currentName,
    String currentEmail,
  ) {
    final nameEditController = TextEditingController(text: currentName);
    final emailEditController = TextEditingController(text: currentEmail);
    bool isSavingLocal = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(
              "Edit Student Info",
              style: TextStyle(color: lnuNavy, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameEditController,
                  decoration: const InputDecoration(labelText: "Full Name"),
                ),
                TextField(
                  controller: emailEditController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSavingLocal ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: lnuNavy),
                onPressed: isSavingLocal
                    ? null
                    : () async {
                        setDialogState(() => isSavingLocal = true);
                        try {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(studentId)
                              .update({
                                'fullName': nameEditController.text.trim(),
                                'email': emailEditController.text
                                    .trim()
                                    .toLowerCase(),
                              });
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          setDialogState(() => isSavingLocal = false);
                          debugPrint("DEBUG: Update error: $e");
                        }
                      },
                child: isSavingLocal
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Save Changes",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _removeStudentFromClass(
    String studentId,
    String studentName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Student"),
        content: Text("Are you sure you want to remove $studentName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classData.id)
          .update({
            'enrolledStudents': FieldValue.arrayRemove([studentId]),
          });
    }
  }

  Future<void> _enrollStudentByEmail() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) return;

    debugPrint("DEBUG: Attempting enrollment for $email");
    setState(() => _isEnrolling = true);

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        debugPrint("DEBUG: No student found with email: $email");
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Student not found!"),
              backgroundColor: Colors.red,
            ),
          );
        setState(() => _isEnrolling = false);
        return;
      }

      final studentDoc = userQuery.docs.first;
      final studentId = studentDoc.id;
      final studentName = studentDoc.data()['fullName'] ?? 'Student';
      debugPrint("DEBUG: Found Student UID: $studentId");

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classData.id)
          .update({
            'enrolledStudents': FieldValue.arrayUnion([studentId]),
          });
      debugPrint(
        "DEBUG: Successfully added $studentId to class ${widget.classData.id}",
      );

      final instructor = ref.read(currentUserProvider).value;
      await _sendEnrollmentEmail(
        studentEmail: email,
        studentName: studentName,
        className: widget.classData.className,
        instructorName: instructor?.fullName ?? 'Instructor',
      );

      if (mounted) _emailController.clear();
    } catch (e) {
      debugPrint("DEBUG: CRITICAL ENROLL ERROR: $e");
    }
    setState(() => _isEnrolling = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.classData.className,
          style: const TextStyle(fontWeight: FontWeight.bold, color: lnuNavy),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lnuNavy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.classData.subject,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.classData.schedule,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "ADD STUDENT",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: "Student Email...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isEnrolling ? null : _enrollStudentByEmail,
                  child: _isEnrolling
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "ENROLL",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              "ENROLLED STUDENTS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(widget.classData.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final List<dynamic> ids =
                      snapshot.data!.get('enrolledStudents') ?? [];

                  return FutureBuilder<List<DocumentSnapshot>>(
                    future: Future.wait(
                      ids.map(
                        (uid) => FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .get(),
                      ),
                    ),
                    builder: (context, userSnaps) {
                      if (!userSnaps.hasData) return const SizedBox();
                      final students = userSnaps.data!;

                      return ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final data =
                              students[index].data() as Map<String, dynamic>?;
                          if (data == null) return const SizedBox();
                          final String name = data['fullName'] ?? 'Unknown';
                          final String email = data['email'] ?? '';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: lnuNavy,
                                ),
                              ),
                              subtitle: Text(email),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    onPressed: () => _showEditStudentDialog(
                                      students[index].id,
                                      name,
                                      email,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () => _removeStudentFromClass(
                                      students[index].id,
                                      name,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
