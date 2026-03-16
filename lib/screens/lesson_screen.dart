import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/lesson_provider.dart';
import '../models/lesson_model.dart';

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(allLessonsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: lessonsAsync.when(
        data: (lessons) {
          if (lessons.isEmpty) return const Center(child: Text('No lessons yet.'));
          return ListView.builder(
            itemCount: lessons.length,
            itemBuilder: (_, index) {
              final LessonModel lesson = lessons[index];

              return Card(
                child: ListTile(
                  title: Text(lesson.title),
                  subtitle: Text(lesson.description),
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