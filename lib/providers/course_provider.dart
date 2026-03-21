import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../repositories/course_repository.dart';
import 'auth_provider.dart';

// Repository
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(FirebaseFirestore.instance);
});

// Instructor view — only this instructor's own courses
final allCoursesProvider = StreamProvider<List<CourseModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value([]);

  // Instructors see only their own courses
  if (user.role == 'instructor') {
    return ref
        .watch(courseRepositoryProvider)
        .getCoursesByInstructor(user.uid);
  }

  // Fallback for any other role — return all (shouldn't hit this in practice)
  return ref.watch(courseRepositoryProvider).getAllCourses();
});

// Student enrolled courses
final enrolledCoursesProvider = StreamProvider<List<CourseModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value([]);
  return ref.watch(courseRepositoryProvider).getEnrolledCourses(user.uid);
});

// Selected course (used by student detail navigation)
final selectedCourseProvider = StateProvider<CourseModel?>((ref) => null);