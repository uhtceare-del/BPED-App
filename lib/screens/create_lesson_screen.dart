import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/lesson_model.dart';
import '../providers/course_provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/cloudinary_provider.dart';

class CreateLessonScreen extends ConsumerStatefulWidget {
  const CreateLessonScreen({super.key});

  @override
  ConsumerState<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends ConsumerState<CreateLessonScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCourseId;
  String? _localFilePath;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp4'],
    );

    if (result != null) {
      setState(() => _localFilePath = result.files.single.path);
    }
  }

  Future<void> _saveLesson() async {
    if (_selectedCourseId == null || _titleController.text.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      String? remoteUrl;
      if (_localFilePath != null) {
        // Use your existing Cloudinary provider to upload
        remoteUrl = await ref.read(cloudinaryProvider).uploadFile(_localFilePath!);
      }

      final newLesson = LessonModel(
        id: '',
        courseId: _selectedCourseId!,
        title: _titleController.text,
        description: _descController.text,
        category: 'Sports Technique', // Use a real category here
        videoUrl: _localFilePath!.endsWith('.mp4') ? remoteUrl : null,
        pdfUrl: _localFilePath!.endsWith('.pdf') ? remoteUrl : null,
      );

      await ref.read(lessonRepositoryProvider).addLesson(newLesson);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(allCoursesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Lesson')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Course Selector
            coursesAsync.when(
              data: (courses) => DropdownButtonFormField<String>(
                hint: const Text("Select Course"),
                items: courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (val) => setState(() => _selectedCourseId = val),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text("Error loading courses"),
            ),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Lesson Title')),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(_localFilePath == null ? "Attach Video or PDF" : "File Selected"),
              subtitle: Text(_localFilePath ?? "No file chosen"),
              trailing: IconButton(icon: const Icon(Icons.cloud_upload), onPressed: _pickFile),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _saveLesson,
                child: _isUploading ? const CircularProgressIndicator() : const Text('Publish Lesson'),
              ),
            )
          ],
        ),
      ),
    );
  }
}