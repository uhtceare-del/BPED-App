import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String name;
  final String description;
  final String instructorId;
  final String? videoUrl; // NEW: Added for the video player
  final List<String>? enrolledStudents;

  CourseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.instructorId,
    this.videoUrl, // Added here
    this.enrolledStudents,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      instructorId: data['instructorId'] ?? '',
      videoUrl: data['videoUrl'], // Map the field from Firestore
      enrolledStudents: List<String>.from(data['enrolledStudents'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'instructorId': instructorId,
      'videoUrl': videoUrl, // Save the URL back to Firestore
      'enrolledStudents': enrolledStudents ?? [],
    };
  }
}