import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/memory.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/storage_service.dart';

class MemoryRepository {
  MemoryRepository(this.coupleId);

  final String coupleId;
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('couples').doc(coupleId).collection('memories');

  /// Real-time stream — sorted by date descending.
  Stream<List<Memory>> watchAll() => _col
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => Memory.fromFirestore(d.data())).toList());

  /// Optimistic add: writes metadata immediately, uploads photo in background.
  Future<void> add(Memory memory) async {
    // 1. Write to Firestore immediately (no photoUrl yet) → UI updates instantly
    await _col.doc(memory.id).set({
      ...memory.toFirestore(),
      'creatorUid': AuthService.uid, // used by Cloud Functions to target partner
    });

    // 2. Upload photo in background
    final file = File(memory.photoPath);
    if (file.existsSync()) {
      try {
        final photoUrl = await StorageService.uploadPhoto(
          coupleId: coupleId,
          memoryId: memory.id,
          file: file,
        );
        // 3. Update Firestore with the download URL
        await _col.doc(memory.id).update({'photoUrl': photoUrl});
      } catch (e) {
        // Upload failed — memory still saved, photo will be missing remotely
        // Can be retried later
      }
    }
  }

  Future<void> update(Memory memory) async {
    await _col.doc(memory.id).update(memory.toFirestore());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
    await StorageService.deletePhoto(coupleId: coupleId, memoryId: id);
  }

  Future<void> toggleFavourite(String id) async {
    final doc = await _col.doc(id).get();
    final current = doc.data()?['isFavourite'] as bool? ?? false;
    await _col.doc(id).update({'isFavourite': !current});
  }

  Future<void> updateReaction(String id, String? reaction) async {
    await _col.doc(id).update({'partnerReaction': reaction});
  }

  Memory? getById(List<Memory> memories, String id) {
    try {
      return memories.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
