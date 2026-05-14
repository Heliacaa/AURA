import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
      await FirestoreService.instance.createUserDoc(
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
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
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

    final user = userCredential.user;
    if (user != null) {
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirestoreService.instance.createUserDoc(
          uid: user.uid,
          displayName: user.displayName ?? '',
          email: user.email ?? '',
          avatarUrl: user.photoURL ?? '',
        );
      } else {
        await FirestoreService.instance.ensureUserDoc(
          uid: user.uid,
          displayName: user.displayName ?? '',
          email: user.email ?? '',
          avatarUrl: user.photoURL ?? '',
        );
      }
    }

    return userCredential;
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
}
