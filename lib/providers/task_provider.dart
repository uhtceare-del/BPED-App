import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/question_model.dart';
import '../repositories/task_repository.dart';
import 'auth_provider.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(firestoreProvider));
});

// Instructor view — only tasks this instructor created
final allTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return Stream.value([]);

  if (user.role == 'instructor') {
    return ref.watch(taskRepositoryProvider).getTasksByInstructor(user.uid);
  }

  // Students see all tasks (filtered by deadline in studentTasksProvider)
  return ref.watch(taskRepositoryProvider).getAllTasks();
});

// Tasks by lesson (used in lesson detail)
final tasksByLessonProvider =
    StreamProvider.family<List<TaskModel>, String>((ref, lessonId) {
  return ref.watch(taskRepositoryProvider).getTasksByLesson(lessonId);
});

// Student tasks — upcoming only, global (instructor-agnostic for students)
final studentTasksProvider =
    StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return Stream.value([]);

  final now = Timestamp.now();

  return ref
      .watch(firestoreProvider)
      .collection('tasks')
      .where('deadline', isGreaterThanOrEqualTo: now)
      .orderBy('deadline')
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
});

// Quiz questions for a task
final questionsByTaskProvider =
    StreamProvider.family<List<QuestionModel>, String>((ref, taskId) {
  return ref.watch(taskRepositoryProvider).getQuestionsByTask(taskId);
});
