import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add url_launcher to pubspec.yaml
import '../models/submission_model.dart';
import '../providers/submission_provider.dart';
import '../providers/auth_provider.dart';

// --- THE MASTER KEY: SECURED SUBMISSION STREAM ---
final securedSubmissionsProvider =
    StreamProvider.autoDispose<List<SubmissionModel>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);

      final isInstructor = user.role.toLowerCase() == 'instructor';
      final db = FirebaseFirestore.instance;

      if (isInstructor) {
        // INSTRUCTOR: See all submissions for tasks THEY assigned
        return db
            .collection('submissions')
            .where('instructorId', isEqualTo: user.uid)
            .snapshots()
            .map(
              (snap) => snap.docs
                  .map((doc) => SubmissionModel.fromFirestore(doc))
                  .toList(),
            );
      } else {
        // STUDENT: Only see their own submissions
        return db
            .collection('submissions')
            .where('studentId', isEqualTo: user.uid)
            .snapshots()
            .map(
              (snap) => snap.docs
                  .map((doc) => SubmissionModel.fromFirestore(doc))
                  .toList(),
            );
      }
    });

class SubmissionScreen extends ConsumerWidget {
  const SubmissionScreen({super.key});
  static const Color lnuNavy = Color(0xFF002147);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(securedSubmissionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Submissions',
          style: TextStyle(fontWeight: FontWeight.bold, color: lnuNavy),
        ),
      ),
      body: submissionsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: lnuNavy)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (submissions) {
          if (submissions.isEmpty)
            return const Center(child: Text('No submissions found.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final sub = submissions[index];
              final isGraded = sub.grade != null && sub.grade!.isNotEmpty;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  title: Text(
                    sub.studentEmail,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Submitted: ${sub.submittedAt.day}/${sub.submittedAt.month}',
                  ),
                  trailing: Icon(
                    Icons.grading,
                    color: isGraded ? Colors.green : Colors.orange,
                  ),
                  onTap: () => _showGradingDialog(context, ref, sub),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showGradingDialog(
    BuildContext context,
    WidgetRef ref,
    SubmissionModel submission,
  ) {
    final gradeController = TextEditingController(text: submission.grade);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- THE DOWNLOAD/VIEW FILE BUTTON ---
            if (submission.fileUrl != null)
              ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse(submission.fileUrl!)),
                icon: const Icon(Icons.download),
                label: const Text("VIEW STUDENT FILE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: gradeController,
              decoration: const InputDecoration(
                labelText: 'Grade (e.g. 95/100)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(submissionRepositoryProvider)
                  .updateGrade(submission.id, gradeController.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
  }
}
