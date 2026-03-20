import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/task_model.dart';
import '../models/submission_model.dart';
import '../providers/submission_provider.dart';
import '../providers/auth_provider.dart';
// Note: Ensure you have a Cloudinary provider set up to handle the actual file upload
// import '../providers/cloudinary_provider.dart';

class StudentTaskDetailScreen extends ConsumerStatefulWidget {
  final TaskModel task;
  const StudentTaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<StudentTaskDetailScreen> createState() => _StudentTaskDetailScreenState();
}

class _StudentTaskDetailScreenState extends ConsumerState<StudentTaskDetailScreen> {
  bool _isUploading = false;

  Future<void> _submitPerformance() async {
    // 1. Pick Video/File
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video, // BPED often requires video for performance tasks
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isUploading = true);

      try {
        // 2. Upload to Cloudinary (Mocking the call here)
        // String? url = await ref.read(cloudinaryProvider).uploadFile(result.files.single.path!);
        String mockUrl = "https://cloudinary.com/videos/sample_performance.mp4";

        // 3. Save Submission to Firestore
        final currentUser = ref.read(authControllerProvider).currentUser;

        final submission = SubmissionModel(
          id: '',
          taskId: widget.task.id,
          studentId: currentUser!.uid,
          studentEmail: currentUser.email ?? '',
          submittedAt: DateTime.now(),
          grade: null, // Initially ungraded
          // videoUrl: mockUrl, // Add this field to your model if needed
        );

        await ref.read(submissionRepositoryProvider).createSubmission(submission);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task submitted successfully!")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Task Details")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.task.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text("Max Score: ${widget.task.maxScore} pts", style: const TextStyle(color: Colors.blue)),
            const Divider(height: 32),
            const Text("Instructions:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.task.description),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _submitPerformance,
                icon: _isUploading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file),
                label: Text(_isUploading ? "Uploading..." : "Upload Performance Video"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}