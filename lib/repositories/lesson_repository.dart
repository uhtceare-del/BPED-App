import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';

class LessonRepository {
  final FirebaseFirestore firestore;
  LessonRepository(this.firestore);

  Stream<List<LessonModel>> getAllLessons() {
    return firestore.collection('lessons').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => LessonModel.fromFirestore(doc)).toList());
  }

  Stream<List<LessonModel>> getLessonsByCourse(String courseId) {
    return firestore
        .collection('lessons')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => LessonModel.fromFirestore(doc)).toList());
  }
}