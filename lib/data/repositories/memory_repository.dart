import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/memory.dart';

class MemoryRepository {
  static const _boxName = 'memories';

  Box<Memory> get _box => Hive.box<Memory>(_boxName);

  static Future<void> init() async {
    Hive.registerAdapter(MemoryAdapter());
    await Hive.openBox<Memory>(_boxName);
  }

  List<Memory> getAll() {
    final memories = _box.values.toList();
    memories.sort((a, b) => b.date.compareTo(a.date));
    return memories;
  }

  Memory? getById(String id) {
    try {
      return _box.values.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(Memory memory) async {
    await _box.put(memory.id, memory);
  }

  Future<void> update(Memory memory) async {
    await _box.put(memory.id, memory);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> toggleFavourite(String id) async {
    final memory = getById(id);
    if (memory != null) {
      memory.isFavourite = !memory.isFavourite;
      await memory.save();
    }
  }

  ValueListenable<Box<Memory>> listenable() => _box.listenable();
}
