import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewerModel {
  final String id;
  final String classId;
  final String title;
  final String fileUrl;
  final DateTime uploadedAt;

  ReviewerModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.fileUrl,
    required this.uploadedAt,
  });

  factory ReviewerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null || data is! Map<String, dynamic>) {
      return ReviewerModel(
        id: doc.id,
        classId: '',
        title: '',
        fileUrl: '',
        uploadedAt: DateTime.now(),
      );
    }
    return ReviewerModel(
      id: doc.id,
      classId: data['classId'] ?? '',
      title: data['title'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'title': title,
      'fileUrl': fileUrl,
      'uploadedAt': uploadedAt,
    };
  }
}