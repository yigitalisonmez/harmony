import 'package:cloud_firestore/cloud_firestore.dart';

class LetterRepository {
  LetterRepository({required this.coupleId, required this.myUid});

  final String coupleId;
  final String myUid;

  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _letterRef(String uid) =>
      _db.collection('couples').doc(coupleId).collection('letters').doc(uid);

  /// Real-time stream of my own letter content.
  Stream<String?> watchMyLetter() => _letterRef(myUid)
      .snapshots()
      .map((s) => s.data()?['content'] as String?);

  /// Real-time stream of partner's letter content.
  /// [partnerUid] comes from the couple's members list.
  Stream<String?> watchPartnerLetter(String partnerUid) =>
      _letterRef(partnerUid)
          .snapshots()
          .map((s) => s.data()?['content'] as String?);

  /// Saves (or overwrites) my letter.
  Future<void> saveLetter(String content) => _letterRef(myUid).set({
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Streams the partner's UID from the couple document members list.
  Stream<String?> watchPartnerUid() => _db
      .collection('couples')
      .doc(coupleId)
      .snapshots()
      .map((s) {
        final members = List<String>.from(s.data()?['members'] ?? []);
        members.remove(myUid);
        return members.isNotEmpty ? members.first : null;
      });
}
