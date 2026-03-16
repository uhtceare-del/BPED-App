import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/submission_provider.dart';
import '../models/submission_model.dart';

class SubmissionScreen extends ConsumerWidget {
  const SubmissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(allSubmissionsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: submissionsAsync.when(
        data: (subs) {
          if (subs.isEmpty) {
            return const Center(child: Text('No submissions yet.'));
          }

          return ListView.builder(
            itemCount: subs.length,
            itemBuilder: (_, index) {
              final SubmissionModel s = subs[index];

              return Card(
                child: ListTile(
                  title: Text(s.studentEmail),
                  subtitle: Text('Submitted: ${s.submittedAt.toLocal()}'),
                  trailing: Text(s.grade?.toString() ?? 'Not graded'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}