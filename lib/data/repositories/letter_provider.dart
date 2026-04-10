import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'letter_repository.dart';
import 'couple_provider.dart';

final letterRepositoryProvider = Provider<LetterRepository?>((ref) {
  final coupleId = ref.watch(coupleIdProvider);
  final user = ref.watch(firebaseUserProvider).valueOrNull;
  if (coupleId == null || user == null) return null;
  return LetterRepository(coupleId: coupleId, myUid: user.uid);
});

/// Stream of the current user's own letter content.
final myLetterProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(letterRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchMyLetter();
});

/// Stream of the partner's UID (null if partner hasn't joined yet).
final partnerUidProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(letterRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchPartnerUid();
});

/// Stream of the partner's letter content.
final partnerLetterProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(letterRepositoryProvider);
  final partnerUid = ref.watch(partnerUidProvider).valueOrNull;
  if (repo == null || partnerUid == null) return const Stream.empty();
  return repo.watchPartnerLetter(partnerUid);
});

/// Exposes [saveMyLetter] for write operations.
final letterNotifierProvider = Provider<LetterNotifier>((ref) {
  final repo = ref.watch(letterRepositoryProvider);
  return LetterNotifier(repo);
});

class LetterNotifier {
  LetterNotifier(this._repo);
  final LetterRepository? _repo;

  Future<void> save(String content) => _repo!.saveLetter(content);
}
