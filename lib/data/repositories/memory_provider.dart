import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/memory.dart';
import 'memory_repository.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository();
});

final memoriesProvider = StateNotifierProvider<MemoriesNotifier, List<Memory>>((ref) {
  final repo = ref.watch(memoryRepositoryProvider);
  return MemoriesNotifier(repo);
});

class MemoriesNotifier extends StateNotifier<List<Memory>> {
  MemoriesNotifier(this._repo) : super([]) {
    _load();
  }

  final MemoryRepository _repo;

  void _load() {
    state = _repo.getAll();
  }

  Future<void> add(Memory memory) async {
    await _repo.add(memory);
    _load();
  }

  Future<void> update(Memory memory) async {
    await _repo.update(memory);
    _load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _load();
  }

  Future<void> toggleFavourite(String id) async {
    await _repo.toggleFavourite(id);
    _load();
  }
}
