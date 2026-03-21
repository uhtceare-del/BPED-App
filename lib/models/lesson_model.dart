import 'package:cloud_firestore/cloud_firestore.dart';

class LessonModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String? videoUrl;
  final String? pdfUrl;
  final String? audioUrl;
  final String? category;
  final String instructorId; // NEW — owner of this lesson

  LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    this.videoUrl,
    this.pdfUrl,
    this.audioUrl,
    this.category,
    this.instructorId = '',
  });

  factory LessonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null || data is! Map<String, dynamic>) {
      return LessonModel(
          id: doc.id, courseId: '', title: '', description: '');
    }
    return LessonModel(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'],
      pdfUrl: data['pdfUrl'],
      audioUrl: data['audioUrl'],
      category: data['category'] ?? '',
      instructorId: data['instructorId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'pdfUrl': pdfUrl,
      'audioUrl': audioUrl,
      'category': category,
      'instructorId': instructorId,
    };
  }
}
