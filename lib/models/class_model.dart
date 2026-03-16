import 'package:cloud_firestore/cloud_firestore.dart';
class ClassModel {
  final String id;
  final String name;
  final String yearLevel;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.name,
    required this.yearLevel,
    required this.createdAt,
  });

  // Factory constructor to create ClassModel from Firestore data
  factory ClassModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ClassModel(
      id: id,
      name: data['name'] ?? '',
      yearLevel: data['yearLevel'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert ClassModel to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'yearLevel': yearLevel,
      'createdAt': createdAt,
    };
  }
}