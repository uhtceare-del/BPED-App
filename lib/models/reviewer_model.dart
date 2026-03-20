import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewerModel {
  final String id;
  final String title;
  final String fileUrl;
  final String category;
  final DateTime uploadedAt;

  ReviewerModel({
    required this.id,
    required this.title,
    required this.fileUrl,
    required this.category,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'fileUrl': fileUrl,
      'category': category,
      'uploadedAt': FieldValue.serverTimestamp(), // Better for Firestore sync
    };
  }

  factory ReviewerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewerModel(
      id: doc.id,
      title: data['title'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      category: data['category'] ?? 'General',
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}