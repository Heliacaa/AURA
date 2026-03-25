import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/auth_service.dart';

/// Firebase auth state stream
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Current authenticated user model from Firestore
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();
  return FirestoreService.instance.userStream(user.uid);
});

/// Auth service instance
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
