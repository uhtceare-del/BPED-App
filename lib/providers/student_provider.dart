import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phys_ed/models/course_model.dart';
import 'auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'course_provider.dart';

final enrolledCoursesProvider =
StreamProvider.autoDispose<List<CourseModel>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('courses')
      .snapshots()
      .map((snapshot) => snapshot.docs
      .map((doc) => CourseModel.fromFirestore(doc))
      .toList());
});

final notificationsProvider =
StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('notifications')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});
final studentCoursesProvider = StreamProvider.autoDispose<List<CourseModel>>((ref) {
  final user = ref.watch(authControllerProvider).currentUser;
  if (user == null) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);

  // Listen to the user's enrolled courses collection
  return firestore
      .collection('users')
      .doc(user.uid)
      .collection('courses')
      .snapshots()
      .asyncMap((snapshot) async {
    // Get list of course IDs
    final courseIds = snapshot.docs.map((doc) => doc.id).toList();

    // Fetch course details from courses collection
    final courseRepo = ref.read(courseRepositoryProvider);
    final courses = await courseRepo.getCoursesByIds(courseIds);

    return courses;
  });
});