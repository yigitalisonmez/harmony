import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';

/// The current Firebase user (null if not signed in).
final firebaseUserProvider = StreamProvider<User?>((ref) {
  return AuthService.authStateChanges;
});

/// The coupleId for the current user. Null if not paired yet.
final coupleIdProvider = StateProvider<String?>((ref) => null);

/// Whether the current user is fully set up (signed in + paired).
final isReadyProvider = Provider<bool>((ref) {
  final user = ref.watch(firebaseUserProvider);
  final coupleId = ref.watch(coupleIdProvider);
  return user.valueOrNull != null && coupleId != null;
});
