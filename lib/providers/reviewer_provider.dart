import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reviewer_model.dart';
import '../repositories/reviewer_repository.dart';
import 'auth_provider.dart';

final reviewerRepositoryProvider = Provider<ReviewerRepository>((ref) {
  return ReviewerRepository(ref.watch(firestoreProvider));
});

// Reviewers by class
final classReviewersProvider = StreamProvider.family<List<ReviewerModel>, String>((ref, classId) {
  return ref.watch(reviewerRepositoryProvider).getReviewersByClass(classId);
});

final allReviewersProvider = StreamProvider<List<ReviewerModel>>((ref) {
  return ref.watch(reviewerRepositoryProvider).getAllReviewers();
});