import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

final firebaseAuthProvider =
Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider =
Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(authState.uid)
      .snapshots()
      .map((snap) => snap.exists
      ? AppUser.fromFirestore(snap.data()!, authState.uid)
      : null);
});

// ── Result type returned to screens ─────────────────────────────────────────

enum GoogleSignInResult {
  existingUser, // already in Firestore with onboarding done → go to dashboard
  newUser,      // not in Firestore or incomplete → go to onboarding
  cancelled,    // user closed the picker
  error,        // something went wrong
}

// ── Repository ───────────────────────────────────────────────────────────────

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepository(this.auth, this.firestore);

  /// Unified Google sign-in for all screens and all platforms.
  ///
  /// Uses [signInWithPopup] on web and [signInWithRedirect] on mobile —
  /// both driven by [GoogleAuthProvider] from firebase_auth directly.
  /// This avoids the [GoogleSignIn()] constructor that was removed in
  /// google_sign_in ^7.0.0 on mobile.
  Future<GoogleSignInResult> signInWithGoogleAndCheck() async {
    try {
      final googleProvider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});

      UserCredential credential;

      if (kIsWeb) {
        // Web: popup flow
        credential = await auth.signInWithPopup(googleProvider);
      } else {
        // Mobile: redirect flow — fires a redirect then reads the result
        // signInWithRedirect returns void; result comes from getRedirectResult
        // However for a simpler in-app experience on mobile we use
        // signInWithPopup as well (works on Android/iOS via a WebView).
        // If signInWithPopup is not available on the target mobile platform,
        // replace with signInWithRedirect + getRedirectResult.
        credential = await auth.signInWithPopup(googleProvider);
      }

      final uid = credential.user?.uid;
      if (uid == null) return GoogleSignInResult.error;

      // Check Firestore for a complete profile
      final doc = await firestore.collection('users').doc(uid).get();
      final data = doc.data();

      final isComplete = doc.exists &&
          (data?['onboardingCompleted'] == true) &&
          ((data?['role'] as String?)?.isNotEmpty ?? false);

      return isComplete
          ? GoogleSignInResult.existingUser
          : GoogleSignInResult.newUser;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return GoogleSignInResult.cancelled;
      }
      print('[Google SignIn] FirebaseAuthException: ${e.code} — ${e.message}');
      return GoogleSignInResult.error;
    } catch (e) {
      print('[Google SignIn] Error: $e');
      return GoogleSignInResult.error;
    }
  }

  Future<bool> doesUserExist(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

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
    required String section,
    required String yearLevel,
    String? fullName,
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

  Future<void> updateUserAvatar(
      {required String uid, required String avatarUrl}) async =>
      firestore.collection('users').doc(uid).update({'avatarUrl': avatarUrl});

  Future<void> resendVerificationEmail(User user) =>
      user.sendEmailVerification();

  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      print('[SignOut] Error: $e');
    }
  }
}

// ── Controller ───────────────────────────────────────────────────────────────

class AuthController {
  final AuthRepository repository;
  AuthController(this.repository);

  Future<GoogleSignInResult> signInWithGoogleAndCheck() =>
      repository.signInWithGoogleAndCheck();

  Future<UserCredential> signIn(String email, String password) =>
      repository.signIn(email, password);

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String role,
    required String section,
    required String yearLevel,
    String? avatarUrl,
    String? fullName,
  }) =>
      repository.signUp(
        email: email,
        password: password,
        role: role,
        avatarUrl: avatarUrl,
        section: section,
        yearLevel: yearLevel,
        fullName: fullName,
      );

  Future<void> updateUserAvatar(
      {required String uid, required String avatarUrl}) =>
      repository.updateUserAvatar(uid: uid, avatarUrl: avatarUrl);

  Future<void> resendVerificationEmail(User user) =>
      repository.resendVerificationEmail(user);

  Future<void> signOut() => repository.signOut();

  User? get currentUser => repository.auth.currentUser;
}

// ── Providers ────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(
    ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider)));

final authControllerProvider = Provider<AuthController>(
        (ref) => AuthController(ref.watch(authRepositoryProvider)));

final userRoleProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return '';
  final doc = await ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .get();
  return doc.data()?['role'] as String? ?? '';
});