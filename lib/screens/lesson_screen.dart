import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lesson_provider.dart';
import '../models/lesson_model.dart';
import 'create_lesson_screen.dart'; // Import the creation screen

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: Ensure this matches the provider name in your lesson_provider.dart
    final lessonsAsync = ref.watch(allLessonsProvider);

    return Scaffold(
      // The body contains your existing logic
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: lessonsAsync.when(
          data: (lessons) {
            if (lessons.isEmpty) {
              return const Center(
                child: Text('No lessons yet. Tap the + to create one!'),
              );
            }
            return ListView.builder(
              itemCount: lessons.length,
              itemBuilder: (_, index) {
                final LessonModel lesson = lessons[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      lesson.videoUrl != null ? Icons.play_circle_fill : Icons.description,
                      color: lesson.videoUrl != null ? Colors.red : Colors.blue,
                    ),
                    title: Text(
                      lesson.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      lesson.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to Lesson Detail/Preview if needed
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),

      // ADDED: Floating Action Button for creation
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateLessonScreen(),
            ),
          );
        },
        label: const Text('Create Lesson'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}