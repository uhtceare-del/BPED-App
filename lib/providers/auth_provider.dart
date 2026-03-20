import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);

  return ref.watch(firestoreProvider)
      .collection('users')
      .doc(authState.uid)
      .snapshots()
      .map((snap) => snap.exists ? AppUser.fromFirestore(snap.data()!, authState.uid) : null);
});

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthRepository(this.auth, this.firestore);

  /// UPDATED: Forcing account selection and removing auto-doc creation
  Future<UserCredential?> signInWithGoogle() async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Forces Google to show the account picker every time
      googleProvider.setCustomParameters({
        'prompt': 'select_account'
      });

      // Use popup for Web, consider signInWithCredential for mobile if needed
      final userCredential = await auth.signInWithPopup(googleProvider);
      return userCredential;
    } catch (e) {
      print("Google Auth Error: $e");
      return null;
    }
  }

  Future<bool> doesUserExist(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  /// UPDATED: Now includes name, year, and section for Google Signups too
  Future<void> completeOnboarding({
    required String uid,
    required String fullName,
    required String role,
    required String yearLevel,
    required String section,
  }) async {
    final user = auth.currentUser;
    await firestore.collection('users').doc(uid).set({
      'fullName': fullName,
      'email': user?.email,
      'role': role,
      'avatarUrl': user?.photoURL ?? '',
      'yearLevel': yearLevel,
      'section': section,
      'onboardingCompleted': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String role,
    String? avatarUrl,
    required String section,    // Now required
    required String yearLevel,  // Now required
    String? fullName,           // Added for consistency
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
        email: email, password: password);

    await firestore.collection('users').doc(cred.user!.uid).set({
      'fullName': fullName ?? email.split('@')[0],
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'section': section,
      'yearLevel': yearLevel,
      'onboardingCompleted': true,
    });

    return cred;
  }

  Future<UserCredential> signIn(String email, String password) =>
      auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> updateUserAvatar({required String uid, required String avatarUrl}) async {
    await firestore.collection('users').doc(uid).update({'avatarUrl': avatarUrl});
  }

  Future<void> resendVerificationEmail(User user) => user.sendEmailVerification();

  Future<void> signOut() async {
    try {
      await auth.signOut();
      if (kIsWeb) {
        await GoogleSignIn.instance.signOut();
        await GoogleSignIn.instance.disconnect();
      } else {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      print("SignOut Error: $e");
    }
  }
}

class AuthController {
  final AuthRepository repository;
  AuthController(this.repository);

  Future<UserCredential?> signInWithGoogle() => repository.signInWithGoogle();
  Future<UserCredential> signIn(String email, String password) => repository.signIn(email, password);

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String role,
    required String section,
    required String yearLevel,
    String? avatarUrl,
    String? fullName,
  }) => repository.signUp(
    email: email,
    password: password,
    role: role,
    avatarUrl: avatarUrl,
    section: section,
    yearLevel: yearLevel,
    fullName: fullName,
  );

  Future<void> updateUserAvatar({required String uid, required String avatarUrl}) {
    return repository.updateUserAvatar(uid: uid, avatarUrl: avatarUrl);
  }

  Future<void> resendVerificationEmail(User user) => repository.resendVerificationEmail(user);
  Future<void> signOut() => repository.signOut();
  User? get currentUser => repository.auth.currentUser;
}

// Providers remain the same
final authRepositoryProvider = Provider<AuthRepository>((ref) =>
    AuthRepository(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider)));

final authControllerProvider = Provider<AuthController>((ref) =>
    AuthController(ref.watch(authRepositoryProvider)));

final userRoleProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return '';
  final doc = await ref.watch(firestoreProvider).collection('users').doc(user.uid).get();
  return doc.data()?['role'] as String? ?? '';
});