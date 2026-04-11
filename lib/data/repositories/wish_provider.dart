import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wish.dart';
import 'couple_provider.dart';
import 'wish_repository.dart';

final wishRepositoryProvider = Provider<WishRepository?>((ref) {
  final coupleId = ref.watch(coupleIdProvider);
  if (coupleId == null) return null;
  return WishRepository(coupleId);
});

final wishesProvider = StreamProvider<List<Wish>>((ref) {
  final repo = ref.watch(wishRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchAll();
});

/// Wishes that haven't been joined yet — shown in "i'd love to" tab.
final pendingWishesProvider = Provider<List<Wish>>((ref) {
  return ref.watch(wishesProvider).valueOrNull?.where((w) => !w.isJoined).toList() ?? [];
});

/// Wishes that both joined — shown in Plans tab.
final joinedWishesProvider = Provider<List<Wish>>((ref) {
  return ref.watch(wishesProvider).valueOrNull?.where((w) => w.isJoined).toList() ?? [];
});
