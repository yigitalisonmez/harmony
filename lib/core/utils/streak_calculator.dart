import '../../data/models/memory.dart';

/// Returns how many consecutive days (ending today or yesterday)
/// have at least one memory.
int calculateStreak(List<Memory> memories) {
  if (memories.isEmpty) return 0;

  final days = memories
      .map((m) => DateTime(m.date.year, m.date.month, m.date.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a)); // newest first

  final today = DateTime.now();
  final todayNorm = DateTime(today.year, today.month, today.day);
  final yesterday = todayNorm.subtract(const Duration(days: 1));

  // Streak must include today or yesterday to be "active"
  if (days.first != todayNorm && days.first != yesterday) return 0;

  int streak = 1;
  for (int i = 1; i < days.length; i++) {
    final expected = days[i - 1].subtract(const Duration(days: 1));
    if (days[i] == expected) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}
