import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phys_ed/models/user_model.dart';
import 'user_provider.dart';


final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Stream to listen to login state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Repository: handles direct Firebase calls
class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepository(this.auth, this.firestore);

  User? get currentUser => auth.currentUser;

  /// Returns UserCredential now
  Future<UserCredential> signIn(String email, String password) async {
    return await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String role,
    String? avatarUrl,
    String? section,
    int? yearLevel,
  }) async {
    final credential =
    await auth.createUserWithEmailAndPassword(email: email, password: password);

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

    await firestore.collection('users').doc(credential.user!.uid).set(userData);

    return credential;
  }

  Future<void> updateUserAvatar({
    required String uid,
    required String avatarUrl,
  }) async {
    await firestore.collection('users').doc(uid).set(
      {'avatarUrl': avatarUrl},
      SetOptions(merge: true),
    );
  }

  Future<void> signOut() async {
    await auth.signOut();
  }
}

/// Controller: interacts with UI / Riverpod
class AuthController {
  final AuthRepository repository;

  AuthController(this.repository);

  // Sign in returns UserCredential
  Future<UserCredential> signIn(String email, String password) {
    return repository.signIn(email, password);
  }

  // Sign up returns UserCredential
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String role,
    String? avatarUrl,
    String? section,
    int? yearLevel,
  }) {
    return repository.signUp(
      email: email,
      password: password,
      role: role,
      avatarUrl: avatarUrl,
      section: section,
      yearLevel: yearLevel,
    );
  }

  Future<void> updateUserAvatar({
    required String uid,
    required String avatarUrl,
  }) {
    return repository.updateUserAvatar(uid: uid, avatarUrl: avatarUrl);
  }

  Future<void> signOut() => repository.signOut();

  User? get currentUser => repository.currentUser;
}

/// Provider for the repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider));
});

/// Provider for the controller
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

/// Provider that fetches the role of the currently signed-in user
final userRoleProvider = FutureProvider<String>((ref) async {
  final authController = ref.watch(authControllerProvider);
  final user = authController.currentUser;

  if (user == null) throw Exception('No user signed in');

  final doc =
  await ref.watch(firestoreProvider).collection('users').doc(user.uid).get();

  final data = doc.data();
  if (data == null) throw Exception('User not found');

  return data['role'] as String? ?? '';
});

final currentUserProvider = Provider<AppUser?>((ref) {
  final user = ref.watch(authControllerProvider).currentUser; // Firebase User
  if (user == null) return null;
  return ref.watch(userRepositoryProvider).getUserById(user.uid); // Returns AppUser
});