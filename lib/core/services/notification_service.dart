import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Top-level handler — required by FCM for background messages.
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage _) async {}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  /// Set by a notification tap; consumed once in HomeScreen to navigate.
  static String? pendingRoute;

  static Future<void> init() async {
    // Register background handler before anything else
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // Request permissions (iOS prompts user; Android 13+ also needs this)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final granted = settings.authorizationStatus ==
            AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (granted) {
      await _saveToken();
      _messaging.onTokenRefresh.listen(_saveTokenString);
    }

    // Show notifications while app is in foreground (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // App launched from a notification tap (terminated state)
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _resolveRoute(initial);

    // App brought to foreground from a notification tap (background state)
    FirebaseMessaging.onMessageOpenedApp.listen(_resolveRoute);
  }

  static void _resolveRoute(RemoteMessage message) {
    final type = message.data['type'] as String?;
    final memoryId = message.data['memoryId'] as String?;
    if (memoryId != null &&
        (type == 'new_memory' || type == 'reaction')) {
      pendingRoute = '/memory/$memoryId';
    }
  }

  static Future<void> _saveToken() async {
    final token = await _messaging.getToken();
    if (token != null) await _saveTokenString(token);
  }

  static Future<void> _saveTokenString(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }
}
