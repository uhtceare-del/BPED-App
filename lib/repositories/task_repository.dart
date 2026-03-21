import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/question_model.dart';

class TaskRepository {
  final FirebaseFirestore firestore;
  TaskRepository(this.firestore);

  Stream<List<TaskModel>> getAllTasks() {
    return firestore
        .collection('tasks')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // Only tasks created by this instructor.
  // Single .where() only — no orderBy — so no composite index required.
  Stream<List<TaskModel>> getTasksByInstructor(String instructorId) {
    return firestore
        .collection('tasks')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  Stream<List<TaskModel>> getTasksByLesson(String lessonId) {
    return firestore
        .collection('tasks')
        .where('lessonId', isEqualTo: lessonId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  Future<String> createTask(TaskModel task) async {
    // Returns the new document ID so the caller can navigate straight
    // to CreateQuestionScreen without a second query
    final doc = await firestore.collection('tasks').add({
      'title': task.title,
      'description': task.description,
      'maxScore': task.maxScore,
      'deadline': Timestamp.fromDate(task.deadline),
      'lessonId': task.lessonId,
      'instructorId': task.instructorId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> addQuestion(QuestionModel question) async {
    await firestore.collection('questions').add(question.toMap());
  }

  Stream<List<QuestionModel>> getQuestionsByTask(String taskId) {
    return firestore
        .collection('questions')
        .where('taskId', isEqualTo: taskId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => QuestionModel.fromFirestore(doc)).toList());
  }

  Future<void> updateGrade(String submissionId, String grade) async {
    await firestore
        .collection('submissions')
        .doc(submissionId)
        .update({'grade': grade});
  }
}
