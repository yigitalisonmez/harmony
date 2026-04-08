import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get uid => _auth.currentUser?.uid;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in anonymously if no user is logged in.
  static Future<UserCredential> signInAnonymously() =>
      _auth.signInAnonymously();

  /// Returns the coupleId for the current user, or null if not paired.
  static Future<String?> getCoupleId() async {
    final uid = AuthService.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['coupleId'] as String?;
  }

  /// Joins an existing couple by start date code, or creates one if it doesn't exist.
  /// Code = DDMMYY (e.g. "220925" for Sep 22, 2025).
  /// Returns coupleId.
  static Future<String> joinOrCreateCouple({
    required String code,
    required DateTime startDate,
  }) async {
    final uid = AuthService.uid!;

    final snap = await _db
        .collection('couples')
        .where('joinCode', isEqualTo: code)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      // Couple exists — join it
      final coupleDoc = snap.docs.first;
      final coupleId = coupleDoc.id;
      final members = List<String>.from(coupleDoc.data()['members'] ?? []);

      if (!members.contains(uid)) {
        final batch = _db.batch();
        batch.update(coupleDoc.reference, {
          'members': FieldValue.arrayUnion([uid]),
        });
        batch.set(_db.collection('users').doc(uid), {
          'coupleId': coupleId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await batch.commit();
      }
      return coupleId;
    } else {
      // No couple with this code — create one
      final coupleRef = _db.collection('couples').doc();
      final coupleId = coupleRef.id;

      final batch = _db.batch();
      batch.set(coupleRef, {
        'members': [uid],
        'joinCode': code,
        'startDate': Timestamp.fromDate(startDate),
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(_db.collection('users').doc(uid), {
        'coupleId': coupleId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      return coupleId;
    }
  }
}
