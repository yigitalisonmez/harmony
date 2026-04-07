import 'package:hive_flutter/hive_flutter.dart';

class SettingsRepository {
  static const _boxName = 'settings';
  static const _startDateKey = 'start_date';
  static const _pinKey = 'secret_pin';
  static const _letterKey = 'secret_letter';

  static Future<void> init() async => Hive.openBox(_boxName);
  static Box get _box => Hive.box(_boxName);

  static DateTime? get startDate {
    final ms = _box.get(_startDateKey) as int?;
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  static Future<void> setStartDate(DateTime d) =>
      _box.put(_startDateKey, d.millisecondsSinceEpoch);

  static String? get pin => _box.get(_pinKey) as String?;
  static Future<void> setPin(String p) => _box.put(_pinKey, p);

  static String get letter => (_box.get(_letterKey) as String?) ?? '';
  static Future<void> setLetter(String l) => _box.put(_letterKey, l);
}
