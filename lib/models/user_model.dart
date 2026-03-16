import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String role;      // e.g., 'student' or 'instructor'
  final String avatarUrl; // optional
  final DateTime createdAt;
  final String? section;  // optional, for class/section assignment
  final int? yearLevel;   // optional, e.g., 1, 2, 3, 4

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.avatarUrl,
    required this.createdAt,
    this.section,
    this.yearLevel,
  });

  // Convert AppUser to a Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      if (section != null) 'section': section,
      if (yearLevel != null) 'yearLevel': yearLevel,
    };
  }

  // Create AppUser from Firestore Map
  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      section: data['section'],
      yearLevel: data['yearLevel'],
    );
  }
}