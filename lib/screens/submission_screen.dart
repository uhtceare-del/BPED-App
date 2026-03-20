// lib/screens/submission_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/submission_model.dart';
import '../providers/submission_provider.dart';

class SubmissionScreen extends ConsumerWidget {
  const SubmissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(submissionProvider);

    return Scaffold(
      body: submissionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (submissions) {
          if (submissions.isEmpty) {
            return const Center(child: Text('No submissions to review yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final sub = submissions[index];
              final isGraded = sub.grade != null && sub.grade!.isNotEmpty;

              return Card(
                margin: const EdgeInsets.only(bottom:12),
                child: ListTile(
                  title: Text(sub.studentEmail),
                  subtitle: Text('Submitted: ${sub.submittedAt.day}/${sub.submittedAt.month}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isGraded ? Colors.green.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isGraded ? 'Grade: ${sub.grade}' : 'Pending',
                      style: TextStyle(color: isGraded ? Colors.green.shade800 : Colors.orange.shade800),
                    ),
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

  void _showGradingDialog(BuildContext context, WidgetRef ref, SubmissionModel submission) {
    final gradeController = TextEditingController(text: submission.grade);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Student's work would appear here (Video/PDF)."),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(submissionRepositoryProvider)
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