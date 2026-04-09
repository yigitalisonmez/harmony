import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/memory.dart';
import 'memory_repository.dart';
import 'couple_provider.dart';

final memoryRepositoryProvider = Provider<MemoryRepository?>((ref) {
  final coupleId = ref.watch(coupleIdProvider);
  if (coupleId == null) return null;
  return MemoryRepository(coupleId);
});

/// Real-time stream of memories from Firestore.
final memoriesProvider = StreamProvider<List<Memory>>((ref) {
  final repo = ref.watch(memoryRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchAll();
});

/// Notifier for write operations (add/delete/toggle).
final memoriesNotifierProvider =
    Provider<MemoriesNotifier>((ref) {
  final repo = ref.watch(memoryRepositoryProvider);
  return MemoriesNotifier(repo);
});

class MemoriesNotifier {
  MemoriesNotifier(this._repo);
  final MemoryRepository? _repo;

  Future<void> add(Memory memory) => _repo!.add(memory);
  Future<void> update(Memory memory) => _repo!.update(memory);
  Future<void> delete(String id) => _repo!.delete(id);
  Future<void> toggleFavourite(String id) => _repo!.toggleFavourite(id);
  Future<void> updateReaction(String id, String? reaction) =>
      _repo!.updateReaction(id, reaction);
}
