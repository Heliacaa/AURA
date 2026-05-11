import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'firestore_service.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirestoreService? firestoreService,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestoreService ?? FirestoreService.instance,
       _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final FirestoreService _firestore;
  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _google => _googleSignIn ??= GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Email/password registration
  Future<UserCredential> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(displayName);

    // Create Firestore user document with defaults
    if (credential.user != null) {
      await _firestore.createUserDoc(
        uid: credential.user!.uid,
        displayName: displayName,
        email: email,
      );
    }

    return credential;
  }

  /// Email/password login
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      await syncUserProfileFromAuth(credential.user!);
    }
    return credential;
  }

  /// Google Sign-In
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google girişi iptal edildi',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.user != null) {
      await syncUserProfileFromAuth(userCredential.user!);
    }

    return userCredential;
  }

  /// Sign in with Apple
  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = appleCredential.identityToken;
      if (identityToken == null) {
        throw FirebaseAuthException(
          code: 'apple-sign-in-missing-token',
          message: 'Apple kimlik tokeni alınamadı.',
        );
      }

      final oauthCredential = OAuthProvider(
        'apple.com',
      ).credential(idToken: identityToken, rawNonce: rawNonce);
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;

      if (user != null) {
        final appleName = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

        if (appleName.isNotEmpty &&
            (user.displayName == null || user.displayName!.isEmpty)) {
          await user.updateDisplayName(appleName);
          await user.reload();
        }

        await syncUserProfileFromAuth(
          _auth.currentUser ?? user,
          fallbackDisplayName: appleName,
        );
      }

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw FirebaseAuthException(
          code: 'apple-sign-in-cancelled',
          message: 'Apple girişi iptal edildi',
        );
      }
      rethrow;
    }
  }

  /// Sync the authenticated provider profile into Firestore if fields are empty.
  Future<void> syncUserProfileFromAuth(
    User user, {
    String fallbackDisplayName = '',
  }) async {
    await _firestore.ensureUserDoc(
      uid: user.uid,
      displayName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : fallbackDisplayName.trim(),
      email: user.email ?? '',
      avatarUrl: user.photoURL ?? '',
    );
  }

  /// Update Firebase Auth display name.
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(displayName);
    await user.reload();
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Google Sign-In may not be initialized on web
    }
    await _auth.signOut();
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
