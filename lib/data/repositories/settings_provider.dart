import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_repository.dart';

class SettingsState {
  final DateTime? startDate;
  final String? pin;
  final String letter;

  const SettingsState({
    this.startDate,
    this.pin,
    this.letter = '',
  });

  int? get daysCount {
    if (startDate == null) return null;
    return DateTime.now().difference(startDate!).inDays;
  }

  SettingsState copyWith({DateTime? startDate, String? pin, String? letter}) =>
      SettingsState(
        startDate: startDate ?? this.startDate,
        pin: pin ?? this.pin,
        letter: letter ?? this.letter,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
          startDate: SettingsRepository.startDate,
          pin: SettingsRepository.pin,
          letter: SettingsRepository.letter,
        ));

  Future<void> setStartDate(DateTime date) async {
    await SettingsRepository.setStartDate(date);
    state = state.copyWith(startDate: date);
  }

  Future<void> setPin(String pin) async {
    await SettingsRepository.setPin(pin);
    state = SettingsState(
        startDate: state.startDate, pin: pin, letter: state.letter);
  }

  Future<void> setLetter(String letter) async {
    await SettingsRepository.setLetter(letter);
    state = SettingsState(
        startDate: state.startDate, pin: state.pin, letter: letter);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
        (ref) => SettingsNotifier());
