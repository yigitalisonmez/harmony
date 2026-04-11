import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/identity_service.dart';
import '../../core/router/app_router.dart' show routerIdentityNotifier;
import '../../data/repositories/couple_provider.dart';
import '../../data/repositories/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                  Text('Settings',
                      style: AppTextStyles.appTitle.copyWith(fontSize: 20)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Relationship ───────────────────────────────────────
                  Text('RELATIONSHIP',
                      style: AppTextStyles.muted.copyWith(fontSize: 10)),
                  const SizedBox(height: 12),
                  _DateTile(
                    currentDate: settings.startDate,
                    onPick: (date) async {
                      await ref
                          .read(settingsProvider.notifier)
                          .setStartDate(date);
                    },
                  ),
                  const SizedBox(height: 24),
                  // ─── Secret ─────────────────────────────────────────────
                  Text('SECRET', style: AppTextStyles.muted.copyWith(fontSize: 10)),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.mail_outline_rounded,
                    iconColor: AppColors.accent,
                    title: 'Secret Letter',
                    subtitle: settings.pin == null
                        ? 'Set a PIN to protect it'
                        : 'Locked with a PIN',
                    onTap: () => context.push('/secret-pin'),
                  ),
                  const SizedBox(height: 24),
                  // ─── Dev ────────────────────────────────────────────────
                  Text('DEV', style: AppTextStyles.muted.copyWith(fontSize: 10)),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.switch_account_outlined,
                    iconColor: Colors.orangeAccent,
                    title: 'Reset Identity',
                    subtitle: 'Switch to a different person',
                    onTap: () async {
                      await IdentityService.clear();
                      ref.read(myNameProvider.notifier).state = null;
                      routerIdentityNotifier.value = false;
                      if (context.mounted) context.go('/identity');
                    },
                  ),
                  const SizedBox(height: 24),
                  // ─── About ──────────────────────────────────────────────
                  Text('ABOUT', style: AppTextStyles.muted.copyWith(fontSize: 10)),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    icon: Icons.favorite,
                    iconColor: AppColors.primary,
                    title: 'harmony',
                    subtitle: 'A private memory journal for two.',
                  ),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    iconColor: AppColors.mutedForeground,
                    title: 'Version',
                    subtitle: '1.0.0',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.currentDate, required this.onPick});

  final DateTime? currentDate;
  final ValueChanged<DateTime> onPick;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: Color(0xFF111111),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    final label = currentDate != null
        ? DateFormat('dd MMMM yyyy').format(currentDate!)
        : 'Tap to set start date';
    final days =
        currentDate != null ? DateTime.now().difference(currentDate!).inDays : null;

    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite_border_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Together since', style: AppTextStyles.bodyBold),
                  Text(label,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.mutedForeground)),
                ],
              ),
            ),
            if (days != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$days days',
                  style: AppTextStyles.muted.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.white30, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyBold),
                  Text(subtitle,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.mutedForeground)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: Colors.white30, size: 18),
          ],
        ),
      ),
    );
  }
}
