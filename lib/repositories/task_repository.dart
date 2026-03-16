import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore firestore;
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
}