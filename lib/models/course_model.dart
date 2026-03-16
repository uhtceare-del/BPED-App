import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String name;
  final String description;
  final String instructorId;
  final List<String>? enrolledStudents; // NEW

  CourseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.instructorId,
    this.enrolledStudents,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      instructorId: data['instructorId'] ?? '',
      enrolledStudents: List<String>.from(data['enrolledStudents'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'instructorId': instructorId,
      'enrolledStudents': enrolledStudents ?? [],
    };
  }
}