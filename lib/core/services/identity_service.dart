import 'package:hive_flutter/hive_flutter.dart';

/// Persists the chosen identity (name) locally on this device.
class IdentityService {
  static const _boxName = 'identity';
  static const _nameKey = 'myName';

  static Future<void> init() => Hive.openBox(_boxName);

  static String? get myName =>
      Hive.box(_boxName).get(_nameKey) as String?;

  static Future<void> setName(String name) =>
      Hive.box(_boxName).put(_nameKey, name);

  static Future<void> clear() =>
      Hive.box(_boxName).delete(_nameKey);
}
