import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/submission_repository.dart';
import '../models/submission_model.dart';
import 'auth_provider.dart'; // make sure you have this

final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  return SubmissionRepository(ref.watch(firestoreProvider));
});

final submissionsByTaskProvider =
StreamProvider.family<List<SubmissionModel>, String>((ref, taskId) {
  return ref.watch(submissionRepositoryProvider).getSubmissionsByTask(taskId);
});

final allSubmissionsProvider =
StreamProvider<List<SubmissionModel>>((ref) {
  return ref.watch(submissionRepositoryProvider).getAllSubmissions();
});