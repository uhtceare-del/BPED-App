import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/course_provider.dart';
import '../models/course_model.dart';

class CourseScreen extends ConsumerWidget {
  const CourseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(instructorCoursesProvider);

    return coursesAsync.when(
      data: (courses) {
        if (courses.isEmpty) {
          return const Center(child: Text('No courses yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (_, index) {
            final CourseModel course = courses[index];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(course.name),
                subtitle: Text(course.description),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}