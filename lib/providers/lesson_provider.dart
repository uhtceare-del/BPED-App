import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/lesson_repository.dart';
import '../models/lesson_model.dart';
import 'auth_provider.dart';

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepository(ref.watch(firestoreProvider));
});

// Instructor view — only lessons belonging to this instructor's courses.
// We filter by instructorId stored on the lesson document.
final allLessonsProvider = StreamProvider<List<LessonModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value([]);

  if (user.role == 'instructor') {
    return ref
        .watch(lessonRepositoryProvider)
        .getLessonsByInstructor(user.uid);
  }

  return ref.watch(lessonRepositoryProvider).getAllLessons();
});

// Lessons by course — used on the course detail screen (both roles)
final lessonsByCourseProvider =
    StreamProvider.family<List<LessonModel>, String>((ref, courseId) {
  return ref.watch(lessonRepositoryProvider).getLessonsByCourse(courseId);
});
