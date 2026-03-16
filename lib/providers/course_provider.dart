import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../repositories/course_repository.dart';
import 'auth_provider.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(ref.watch(firestoreProvider));
});

// Instructor's courses
final instructorCoursesProvider = StreamProvider<List<CourseModel>>((ref) {
  final user = ref.watch(authControllerProvider).currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(courseRepositoryProvider).getCoursesByInstructor(user.uid);
});