import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reviewer_provider.dart';
import '../models/reviewer_model.dart';

class ReviewerScreen extends ConsumerWidget {
  const ReviewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewersAsync = ref.watch(allReviewersProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: reviewersAsync.when(
        data: (reviewers) {
          if (reviewers.isEmpty) {
            return const Center(child: Text('No reviewers uploaded.'));
          }

          return ListView.builder(
            itemCount: reviewers.length,
            itemBuilder: (_, index) {
              final ReviewerModel reviewer = reviewers[index];

              return Card(
                child: ListTile(
                  title: Text(reviewer.title),
                  subtitle: Text(
                    'Uploaded: ${reviewer.uploadedAt.toLocal()}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      // Implement download/open logic
                    },
                  ),
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