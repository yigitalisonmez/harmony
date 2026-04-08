import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/memory_provider.dart';
import '../../data/repositories/settings_provider.dart';
import '../../data/repositories/bucket_list_provider.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories   = ref.watch(memoriesProvider).valueOrNull ?? [];
    final settings   = ref.watch(settingsProvider);
    final pixelCount  = memories.where((m) => m.pixelMap != null).length;
    final favCount    = memories.where((m) => m.isFavourite).length;
    final bucketItems = ref.watch(bucketListProvider);
    final bucketDone  = bucketItems.where((i) => i.isCompleted).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
          children: [
            // ── Header ──────────────────────────────────────────────────
            Text('explore',
                style: AppTextStyles.appTitle.copyWith(fontSize: 30)),
            if (settings.daysCount != null) ...[
              const SizedBox(height: 4),
              Text(
                '${settings.daysCount} days of us  ♡',
                style: AppTextStyles.muted.copyWith(
                  fontSize: 13,
                  color: AppColors.primary.withValues(alpha: 0.75),
                ),
              ),
            ],
            const SizedBox(height: 22),

            // ── Stat chips ──────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _Chip(value: '${memories.length}', label: 'memories'),
                  const SizedBox(width: 8),
                  _Chip(value: '$favCount', label: 'favourites'),
                  const SizedBox(width: 8),
                  _Chip(value: '$pixelCount', label: 'pixel maps'),
                  if (settings.startDate != null) ...[
                    const SizedBox(width: 8),
                    _Chip(
                      value: DateFormat('MMM yy').format(settings.startDate!),
                      label: 'since',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Grid: Calendar + Pixel Maps ──────────────────────────────
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _FeatureCard(
                      imagePath: 'assets/images/calendar_3d.png',
                      label: 'CALENDAR',
                      title: 'Memories\nin time',
                      onTap: () => context.push('/calendar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FeatureCard(
                      imagePath: 'assets/images/pixelmap_3d.png',
                      label: 'PIXEL MAPS',
                      title: '$pixelCount\nportraits',
                      onTap: () => context.push('/pixelmap-gallery'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Bucket List ──────────────────────────────────────────────
            _FeatureRow(
              imagePath: 'assets/images/bucketlist_3d.png',
              label: 'BUCKET LIST',
              subtitle: bucketItems.isEmpty
                  ? 'Things to experience together'
                  : '$bucketDone of ${bucketItems.length} completed',
              onTap: () => context.push('/bucket-list'),
            ),
            const SizedBox(height: 12),

            // ── Secret Letter ────────────────────────────────────────────
            _FeatureRow(
              imagePath: 'assets/images/letter_3d.png',
              label: 'SECRET LETTER',
              subtitle: settings.pin == null
                  ? 'Write something only for her'
                  : 'Locked · tap to open',
              onTap: () => context.push('/secret-pin'),
            ),
            const SizedBox(height: 12),

            // ── Settings ─────────────────────────────────────────────────
            _FeatureRow(
              imagePath: 'assets/images/settings_3d.png',
              label: 'SETTINGS',
              subtitle: 'Start date, PIN and more',
              onTap: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Square card ─────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.label,
    required this.title,
    required this.onTap,
    this.icon,
    this.iconColor,
    this.imagePath,
  });

  final IconData? icon;
  final Color? iconColor;
  final String? imagePath;
  final String label;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 175),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagePath != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  imagePath!,
                  width: 82,
                  height: 82,
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
              ),
            const Spacer(),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.5,
                color: Colors.white.withValues(alpha: 0.3),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: AppTextStyles.bodyBold.copyWith(
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wide row card ────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.icon,
    this.iconColor,
    this.imagePath,
  });

  final IconData? icon;
  final Color? iconColor;
  final String? imagePath;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          children: [
            // image veya icon
            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              )
            else
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor ?? AppColors.primary, size: 21),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.5,
                      color: Colors.white.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.body.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.2),
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat chip ────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style:
                  AppTextStyles.bodyBold.copyWith(fontSize: 13)),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.muted.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
