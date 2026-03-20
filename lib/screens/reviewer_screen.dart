import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/reviewer_provider.dart';
import '../models/reviewer_model.dart';

class ReviewerScreen extends ConsumerWidget {
  const ReviewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewersAsync = ref.watch(allReviewersProvider);

    return Scaffold(
      body: reviewersAsync.when(
        data: (reviewers) {
          if (reviewers.isEmpty) {
            return const Center(child: Text('No reviewers uploaded. Tap + to add.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviewers.length,
            itemBuilder: (_, index) {
              final reviewer = reviewers[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text(reviewer.title),
                  subtitle: Text('Category: ${reviewer.category}'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    // logic to launch URL in browser or PDF viewer
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleFileUpload(context, ref),
        label: const Text("Upload Reviewer"),
        icon: const Icon(Icons.upload_file),
      ),
    );
  }

  Future<void> _handleFileUpload(BuildContext context, WidgetRef ref) async {
    // 1. Pick the PDF
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      // 2. Here you would call your CloudinaryProvider to get the URL
      // 3. Then save the ReviewerModel to Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File selected. Starting upload...")),
      );
    }
  }
}