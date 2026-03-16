import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class AuthController {
  final AuthRepository repository;

  AuthController(this.repository);

  // Sign in returns UserCredential
  Future<UserCredential> signIn(String email, String password) {
    return repository.signIn(email, password);
  }

  // Sign up returns UserCredential with section and yearLevel
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String role,
    String? avatarUrl,
    String? section,
    int? yearLevel,
  }) {
    // Pass the new parameters to repository
    return repository.signUp(
      email: email,
      password: password,
      role: role,
      avatarUrl: avatarUrl,
      section: section,
      yearLevel: yearLevel,
    );
  }

  // Update user avatar
  Future<void> updateUserAvatar({
    required String uid,
    required String avatarUrl,
  }) {
    return repository.updateUserAvatar(uid: uid, avatarUrl: avatarUrl);
  }

  // Sign out
  Future<void> signOut() => repository.signOut();

  // Current user
  User? get currentUser => repository.auth.currentUser;
}