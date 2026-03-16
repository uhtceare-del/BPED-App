import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  final String id;
  final String courseId;
  final String title;
  final String description;

  LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
  });

  // Factory constructor from Firestore
  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null || data is! Map<String, dynamic>) {
      // Return empty/default values if data is null
      return LessonModel(
        id: doc.id,
        courseId: '',
        title: '',
        description: '',
      );
    }

    return LessonModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
    };
  }
}