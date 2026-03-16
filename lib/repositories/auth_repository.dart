import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepository({required this.auth, required this.firestore});

  /// Sign in a user
  Future<UserCredential> signIn(String email, String password) async {
    return await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Sign up a user
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String role,
    String? avatarUrl,
    String? section,
    int? yearLevel,
  }) async {
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userData = {
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (role == 'student') {
      userData['section'] = section ?? '';
      userData['yearLevel'] = yearLevel ?? 1;
      userData['enrolledCourses'] = <String>[];
    }

    final userDoc = firestore.collection('users').doc(userCredential.user!.uid);
    await userDoc.set(userData);

    return userCredential;
  }

  /// Update user avatar in Firestore
  Future<void> updateUserAvatar({
    required String uid,
    required String avatarUrl,
  }) async {
    final userDoc = firestore.collection('users').doc(uid);
    await userDoc.set({'avatarUrl': avatarUrl}, SetOptions(merge: true));
  }

  /// Sign out
  Future<void> signOut() async {
    await auth.signOut();
  }
}