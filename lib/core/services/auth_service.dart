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

  /// Saves the user's display name to Firestore (users + couples docs).
  static Future<void> setName(String coupleId, String name) async {
    final uid = AuthService.uid!;
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(uid), {'name': name});
    batch.update(_db.collection('couples').doc(coupleId), {
      'names.$uid': name,
    });
    await batch.commit();
  }

  /// Returns the name for the current user from Firestore, or null.
  static Future<String?> getMyName() async {
    final uid = AuthService.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['name'] as String?;
  }

  /// Returns all {uid → name} entries for the couple.
  static Future<Map<String, String>> getCoupleNames(String coupleId) async {
    final doc = await _db.collection('couples').doc(coupleId).get();
    final raw = doc.data()?['names'] as Map<String, dynamic>? ?? {};
    return raw.map((k, v) => MapEntry(k, v as String));
  }

  /// The one and only valid access code for this couple.
  static const coupleAccessCode = '210925';

  /// Validates the code and connects this device to the couple.
  /// Returns the coupleId on success, throws on wrong code or not found.
  static Future<String> loginWithCode(String code) async {
    if (code != coupleAccessCode) {
      throw Exception('wrong_code');
    }

    final uid = AuthService.uid!;

    final snap = await _db
        .collection('couples')
        .where('joinCode', isEqualTo: code)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception('couple_not_found');
    }

    final coupleDoc = snap.docs.first;
    final coupleId = coupleDoc.id;
    final members = List<String>.from(coupleDoc.data()['members'] ?? []);

    // Add this UID to members if not already there
    if (!members.contains(uid)) {
      await _db.batch()
        ..update(coupleDoc.reference, {
          'members': FieldValue.arrayUnion([uid]),
        })
        ..set(_db.collection('users').doc(uid), {
          'coupleId': coupleId,
          'createdAt': FieldValue.serverTimestamp(),
        })
        ..commit();
    } else {
      // Already a member — just make sure users doc is up to date
      await _db.collection('users').doc(uid).set(
        {'coupleId': coupleId},
        SetOptions(merge: true),
      );
    }

    return coupleId;
  }
}
