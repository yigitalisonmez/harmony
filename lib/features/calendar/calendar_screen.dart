import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/memory_image.dart' show MemoryPhotoView;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/memory.dart';
import '../../data/repositories/memory_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final memories = ref.watch(memoriesProvider).valueOrNull ?? [];

    final memoryMap = <DateTime, List<Memory>>{};
    for (final m in memories) {
      final key = DateTime(m.date.year, m.date.month, m.date.day);
      memoryMap.putIfAbsent(key, () => []).add(m);
    }

    final selectedMems =
        _selected != null ? (memoryMap[_selected] ?? []) : <Memory>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context),
            const SizedBox(height: 12),
            _buildMonthNav(),
            const SizedBox(height: 16),
            _buildWeekLabels(),
            const SizedBox(height: 6),
            _buildDayGrid(memoryMap),
            const SizedBox(height: 8),
            if (_selected != null) ...[
              _buildSelectedDayHeader(selectedMems),
              Expanded(child: _buildMemoryList(selectedMems)),
            ] else
              const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Calendar',
                  style: AppTextStyles.appTitle.copyWith(fontSize: 20)),
              Text('memories in time', style: AppTextStyles.muted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavBtn(
          icon: Icons.chevron_left,
          onTap: () => setState(() {
            _focused = DateTime(_focused.year, _focused.month - 1);
            _selected = null;
          }),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 160,
          child: Text(
            DateFormat('MMMM yyyy').format(_focused).toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyBold.copyWith(letterSpacing: 1.5),
          ),
        ),
        const SizedBox(width: 20),
        _NavBtn(
          icon: Icons.chevron_right,
          onTap: () => setState(() {
            _focused = DateTime(_focused.year, _focused.month + 1);
            _selected = null;
          }),
        ),
      ],
    );
  }

  Widget _buildWeekLabels() {
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: days
            .map((d) => Expanded(
                  child: Center(
                    child: Text(d,
                        style: AppTextStyles.muted
                            .copyWith(fontSize: 11, letterSpacing: 0.5)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDayGrid(Map<DateTime, List<Memory>> memoryMap) {
    final firstDay = DateTime(_focused.year, _focused.month, 1);
    final daysInMonth =
        DateTime(_focused.year, _focused.month + 1, 0).day;
    final offset = (firstDay.weekday - 1) % 7;
    final today = DateTime.now();

    final cells = <Widget>[
      for (int i = 0; i < offset; i++) const SizedBox(),
      for (int day = 1; day <= daysInMonth; day++)
        Builder(builder: (_) {
          final date = DateTime(_focused.year, _focused.month, day);
          final dayMems = memoryMap[date] ?? [];
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          final isSelected = _selected == date;

          return _DayCell(
            day: day,
            memories: dayMems,
            isToday: isToday,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selected = (_selected == date) ? null : date;
              });
            },
          );
        }),
    ];

    return SizedBox(
      height: 300,
      child: GridView.count(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        physics: const NeverScrollableScrollPhysics(),
        children: cells,
      ),
    );
  }

  Widget _buildSelectedDayHeader(List<Memory> mems) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Row(
        children: [
          Text(
            DateFormat('MMMM d').format(_selected!).toUpperCase(),
            style: AppTextStyles.label,
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${mems.length} ${mems.length == 1 ? 'memory' : 'memories'}',
              style: AppTextStyles.muted.copyWith(
                color: AppColors.primary,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryList(List<Memory> mems) {
    if (mems.isEmpty) {
      return Center(
        child: Text('this day slipped by quietly — go make tomorrow unforgettable ♡',
            textAlign: TextAlign.center,
            style: AppTextStyles.muted),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: mems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _MemoryListTile(
        memory: mems[i],
        onTap: () => context.push('/memory/${mems[i].id}'),
      ),
    );
  }
}

// ── Memory list tile ─────────────────────────────────────────────────────────
class _MemoryListTile extends StatelessWidget {
  const _MemoryListTile({required this.memory, required this.onTap});
  final Memory memory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              child: SizedBox(
                width: 80,
                height: 80,
                child: MemoryPhotoView(
                  photoPath: memory.photoPath,
                  photoUrl: memory.photoUrl,
                  cacheWidth: 160,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (memory.note?.isNotEmpty == true)
                    Text(
                      memory.note!,
                      style: AppTextStyles.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (memory.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 11,
                            color: AppColors.mutedForeground),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            memory.location!,
                            style: AppTextStyles.muted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (memory.isFavourite) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.favorite_rounded,
                            size: 11, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text('liked',
                            style: AppTextStyles.muted
                                .copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),
            Icon(Icons.arrow_forward_ios,
                size: 12, color: Colors.white.withValues(alpha: 0.25)),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

// ── Day cell ─────────────────────────────────────────────────────────────────
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.memories,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final int day;
  final List<Memory> memories;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = memories.isNotEmpty;
    final firstMemory = has ? memories.first : null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : isToday
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : isToday
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 1)
                  : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo thumbnail background
              if (firstMemory != null)
                Opacity(
                  opacity: isSelected ? 0.5 : 0.35,
                  child: MemoryPhotoView(
                    photoPath: firstMemory.photoPath,
                    photoUrl: firstMemory.photoUrl,
                    cacheWidth: 80,
                  ),
                ),

              // Day number + dot
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: has ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : isToday
                              ? AppColors.primary
                              : has
                                  ? Colors.white
                                  : Colors.white
                                      .withValues(alpha: 0.25),
                    ),
                  ),
                  if (has) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0;
                            i < memories.length.clamp(0, 3);
                            i++)
                          Container(
                            width: 3,
                            height: 3,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white
                                      .withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav button ────────────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}
