import 'dart:typed_data'; // ADDED: For handling raw bytes on Web
import 'package:flutter/foundation.dart'
    show kIsWeb; // ADDED: To check if running on Web
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';
import '../providers/lesson_provider.dart';
import '../providers/cloudinary_provider.dart';
import '../providers/auth_provider.dart';

class CreateLessonScreen extends ConsumerStatefulWidget {
  const CreateLessonScreen({super.key});

  @override
  ConsumerState<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends ConsumerState<CreateLessonScreen> {
  static const Color lnuNavy = Color(0xFF002147);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedCourseId;

  // --- NEW: SAFE FILE HANDLING VARIABLES ---
  String? _localFilePath; // Used for Mobile
  Uint8List? _fileBytes; // Used for Web
  String? _fileName; // Used for both to check extensions

  bool _isUploading = false;

  Future<void> _pickFile() async {
    // FIXED: Added withData: true which is REQUIRED for Web to grab bytes!
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp4'],
      withData: kIsWeb,
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
        if (kIsWeb) {
          // WEB: Grab the raw bytes safely
          _fileBytes = result.files.single.bytes;
        } else {
          // MOBILE: Grab the physical path safely
          _localFilePath = result.files.single.path;
        }
      });
    }
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate() || _selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and select a course"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      String? remoteUrl;

      // --- SAFE UPLOAD LOGIC FOR WEB & MOBILE ---
      if (kIsWeb && _fileBytes != null) {
        // IMPORTANT: Your cloudinaryProvider needs an 'uploadFileBytes' function to accept web bytes!
        // We will pass the bytes and the filename to it.
        remoteUrl = await ref
            .read(cloudinaryProvider)
            .uploadFileBytes(_fileBytes!, _fileName!);
      } else if (!kIsWeb && _localFilePath != null) {
        remoteUrl = await ref
            .read(cloudinaryProvider)
            .uploadFile(_localFilePath!);
      }

      // FIXED: Check the extension using the _fileName instead of path
      final isVideo =
          _fileName != null && _fileName!.toLowerCase().endsWith('.mp4');
      final isPdf =
          _fileName != null && _fileName!.toLowerCase().endsWith('.pdf');

      final newLesson = LessonModel(
        id: '',
        courseId: _selectedCourseId!,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: 'Sports Technique',
        videoUrl: isVideo ? remoteUrl : null,
        pdfUrl: isPdf ? remoteUrl : null,
        instructorId: user.uid,
      );

      await ref.read(lessonRepositoryProvider).addLesson(newLesson);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lesson published successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Create New Lesson',
          style: TextStyle(fontWeight: FontWeight.bold, color: lnuNavy),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: lnuNavy),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .where('instructorId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: lnuNavy),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Text(
                        "You must create a Course first before adding lessons!",
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  final courses = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Assign to Course",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    initialValue: _selectedCourseId,
                    items: courses.map((c) {
                      final data = c.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          data['name'] ?? 'Unnamed Course',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: lnuNavy,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCourseId = val),
                  );
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Lesson Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: lnuNavy.withOpacity(0.1),
                    child: const Icon(Icons.attach_file, color: lnuNavy),
                  ),
                  title: Text(
                    _fileName == null
                        ? "Attach Video or PDF (Optional)"
                        : "File Selected",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _fileName ?? "No file chosen",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lnuNavy,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.cloud_upload, size: 18),
                    label: const Text("BROWSE"),
                    onPressed: _pickFile,
                  ),
                ),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lnuNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isUploading ? null : _saveLesson,
                  child: _isUploading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'PUBLISH LESSON',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
