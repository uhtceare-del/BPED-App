import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';

class CourseRepository {
  final FirebaseFirestore firestore;

  CourseRepository(this.firestore);

  /// Fetch all courses
  Stream<List<CourseModel>> getAllCourses() {
    return firestore.collection('courses').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList());
  }

  /// Fetch courses by instructor
  Stream<List<CourseModel>> getCoursesByInstructor(String instructorId) {
    return firestore
        .collection('courses')
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList());
  }

  /// Fetch multiple courses by a list of course IDs
  Future<List<CourseModel>> getCoursesByIds(List<String> courseIds) async {
    if (courseIds.isEmpty) return [];

    final chunks = <List<String>>[];
    const chunkSize = 10; // Firestore whereIn max is 10
    for (var i = 0; i < courseIds.length; i += chunkSize) {
      chunks.add(courseIds.sublist(
          i, i + chunkSize > courseIds.length ? courseIds.length : i + chunkSize));
    }

    final List<CourseModel> courses = [];
    for (var chunk in chunks) {
      final snapshot = await firestore
          .collection('courses')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      courses.addAll(snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)));
    }

    return courses;
  }

  /// Fetch all courses once (one-time snapshot)
  Future<List<CourseModel>> getAllCoursesOnce() async {
    final snapshot = await firestore.collection('courses').get();
    return snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
  }
  Stream<List<CourseModel>> getEnrolledCourses(String studentId) {
    return firestore
        .collection('courses')
        .where('enrolledStudents', arrayContains: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CourseModel.fromFirestore(doc))
        .toList());
  }
/// Add this to your CourseRepository class
  Future<void> createCourse(CourseModel course) async {
    await firestore.collection('courses').add(course.toMap());
  }
  /// ✅ Enroll a student in a course
  Future<void> enrollStudentInCourse({
    required String courseId,
    required String studentId,
  }) async {
    final courseRef = firestore.collection('courses').doc(courseId);
    final studentRef = firestore.collection('users').doc(studentId);

    // Update course document
    final courseDoc = await courseRef.get();
    List<String> enrolledStudents = [];
    if (courseDoc.exists) {
      enrolledStudents = List<String>.from(courseDoc['enrolledStudents'] ?? []);
    }
    if (!enrolledStudents.contains(studentId)) {
      enrolledStudents.add(studentId);
      await courseRef.set({'enrolledStudents': enrolledStudents}, SetOptions(merge: true));
    }

    // Update student document
    final studentDoc = await studentRef.get();
    List<String> enrolledCourses = [];
    if (studentDoc.exists) {
      enrolledCourses = List<String>.from(studentDoc['enrolledCourses'] ?? []);
    }
    if (!enrolledCourses.contains(courseId)) {
      enrolledCourses.add(courseId);
      await studentRef.set({'enrolledCourses': enrolledCourses}, SetOptions(merge: true));
    }
  }
}