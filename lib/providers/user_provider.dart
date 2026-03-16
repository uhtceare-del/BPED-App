import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(firestoreProvider));
});

// Stream of all students (optional: filter by class or year)
final studentsProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).getAllStudents();
});

// Current logged-in user
final currentUserProvider = Provider<AppUser?>((ref) {
  final user = ref.watch(authControllerProvider).currentUser;
  if (user == null) return null;
  return ref.watch(userRepositoryProvider).getUserById(user.uid);
});

final avatarUrlProvider = StreamProvider<String?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    final data = doc.data();
    if (data == null) return null;
    return data['avatarUrl'] as String?;
  });
});