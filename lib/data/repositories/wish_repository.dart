import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/wish.dart';

class WishRepository {
  WishRepository(this.coupleId);
  final String coupleId;
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('couples').doc(coupleId).collection('wishes');

  Stream<List<Wish>> watchAll() => _col
      .snapshots()
      .map((s) {
        final list = s.docs.map((d) => Wish.fromFirestore(d.data())).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  Future<void> add(String text, String creatorUid, String creatorName) async {
    final id = const Uuid().v4();
    await _col.doc(id).set(Wish(
          id: id,
          text: text,
          creatorUid: creatorUid,
          creatorName: creatorName,
          createdAt: DateTime.now(),
        ).toFirestore());
  }

  Future<void> join(String wishId, String joinedUid, String joinedName) async {
    await _col.doc(wishId).update({
      'joinedUid': joinedUid,
      'joinedName': joinedName,
    });
  }

  Future<void> delete(String wishId) => _col.doc(wishId).delete();
}
