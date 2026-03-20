import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/question_model.dart'; // <--- ADD THIS LINE
import '../repositories/task_repository.dart';
import 'auth_provider.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(firestoreProvider));
});
final tasksByLessonProvider = StreamProvider.family<List<TaskModel>, String>((ref, lessonId) {
  return ref.watch(taskRepositoryProvider).getTasksByLesson(lessonId);
});
final allTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  return ref.watch(taskRepositoryProvider).getAllTasks();
});

// Student tasks (filtered by current user)
final studentTasksProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);

  // Use Timestamp.now() to avoid errors
  final now = Timestamp.now();

  return ref.watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .collection('tasks')
      .where('deadline', isGreaterThanOrEqualTo: now)
      .orderBy('deadline')
      .snapshots()
      .map((snapshot) => snapshot.docs
      .map((doc) => TaskModel.fromFirestore(doc))
      .toList());
});
final questionsByTaskProvider = StreamProvider.family<List<QuestionModel>, String>((ref, taskId) {
  return ref.watch(taskRepositoryProvider).getQuestionsByTask(taskId);
});