import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../repositories/course_repository.dart';
import 'auth_provider.dart';

// 1. The Repository Provider
// Provides an instance of the repository to the rest of the app
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(FirebaseFirestore.instance);
});

// 2. All Courses Provider
// Fetches the entire collection of PE courses for the dashboard
final allCoursesProvider = StreamProvider<List<CourseModel>>((ref) {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getAllCourses();
});

// 3. Enrolled Courses Provider
// Fetches only courses linked to the current user's UID
final enrolledCoursesProvider = StreamProvider<List<CourseModel>>((ref) {
  // We watch the current user from your authController
  final user = ref.watch(currentUserProvider).value;

  if (user == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(courseRepositoryProvider);
  return repository.getEnrolledCourses(user.uid);
});

// 4. Selected Course Provider
// Used to keep track of which course the student clicked on
final selectedCourseProvider = StateProvider<CourseModel?>((ref) => null);