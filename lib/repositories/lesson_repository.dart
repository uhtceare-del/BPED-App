import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson_model.dart';

class LessonRepository {
  final FirebaseFirestore firestore;
  LessonRepository(this.firestore);

  Stream<List<LessonModel>> getAllLessons() {
    return firestore
        .collection('lessons')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => LessonModel.fromFirestore(doc)).toList());
  }

  // Only lessons created by this instructor.
  // Single .where() only — no orderBy — so no composite index required.
  Stream<List<LessonModel>> getLessonsByInstructor(String instructorId) {
    return firestore
        .collection('lessons')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => LessonModel.fromFirestore(doc)).toList());
  }

  // Lessons for a specific course — single .where(), no index needed
  Stream<List<LessonModel>> getLessonsByCourse(String courseId) {
    return firestore
        .collection('lessons')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => LessonModel.fromFirestore(doc)).toList());
  }

  Future<void> addLesson(LessonModel lesson) async {
    await firestore.collection('lessons').add(lesson.toMap());
  }

  Future<void> createLesson(LessonModel lesson) async {
    await firestore.collection('lessons').add(lesson.toMap());
  }
}
