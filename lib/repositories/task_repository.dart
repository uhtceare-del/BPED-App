import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/question_model.dart';

class TaskRepository {
  final FirebaseFirestore firestore; // Your variable name
  TaskRepository(this.firestore);

  Stream<List<TaskModel>> getAllTasks() {
    return firestore.collection('tasks').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  Stream<List<TaskModel>> getTasksByLesson(String lessonId) {
    return firestore
        .collection('tasks')
        .where('lessonId', isEqualTo: lessonId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // --- NEW: Quiz Question Methods ---

  Future<void> addQuestion(QuestionModel question) async {
    await firestore.collection('questions').add(question.toMap());
  }
  Future<void> updateGrade(String submissionId, String grade) async {
    await firestore.collection('submissions').doc(submissionId).update({
      'grade': grade,
    });
  }

  Future<void> createTask(TaskModel task) async {
    // FIXED: Changed _firestore to firestore to match the class variable
    await firestore.collection('tasks').add({
      'title': task.title,
      'description': task.description,
      'maxScore': task.maxScore,
      'deadline': task.deadline,
      'lessonId': task.lessonId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<QuestionModel>> getQuestionsByTask(String taskId) {
    return firestore
        .collection('questions')
        .where('taskId', isEqualTo: taskId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => QuestionModel.fromFirestore(doc)).toList());
  }
}