import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/settings_provider.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _entered = '';
  String _firstPin = '';
  bool _error = false;
  late bool _settingUp;

  @override
  void initState() {
    super.initState();
    _settingUp = ref.read(settingsProvider).pin == null;
  }

  void _onDigit(String d) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += d;
      _error = false;
    });
    if (_entered.length == 4) _submit();
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    if (_settingUp) {
      if (_firstPin.isEmpty) {
        // Ask to confirm
        setState(() {
          _firstPin = _entered;
          _entered = '';
        });
      } else if (_entered == _firstPin) {
        await ref.read(settingsProvider.notifier).setPin(_entered);
        if (mounted) context.replace('/secret-letter');
      } else {
        setState(() {
          _firstPin = '';
          _entered = '';
          _error = true;
        });
      }
    } else {
      final correct = ref.read(settingsProvider).pin;
      if (_entered == correct) {
        if (mounted) context.replace('/secret-letter');
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _entered = '';
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConfirm = _settingUp && _firstPin.isNotEmpty;
    final subtitle = _settingUp
        ? (isConfirm ? 'confirm your PIN' : 'choose a 4-digit PIN')
        : 'enter your PIN';

    return Scaffold(
      backgroundColor: const Color(0xFF060606),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
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
              ),
            ),
            const Spacer(),
            const Icon(Icons.lock_outline_rounded,
                color: AppColors.primary, size: 44),
            const SizedBox(height: 16),
            Text('secret letter',
                style: AppTextStyles.appTitle.copyWith(fontSize: 22)),
            const SizedBox(height: 6),
            Text(subtitle, style: AppTextStyles.muted),
            if (_error) ...[
              const SizedBox(height: 8),
              Text('Incorrect PIN.',
                  style: AppTextStyles.muted
                      .copyWith(color: Colors.redAccent, fontSize: 12)),
            ],
            const SizedBox(height: 40),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _entered.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? (_error ? Colors.redAccent : AppColors.primary)
                        : Colors.white.withValues(alpha: 0.15),
                    boxShadow: filled
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                            )
                          ]
                        : [],
                  ),
                );
              }),
            ),
            const Spacer(),
            // Numpad
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 48, 48),
              child: Column(
                children: [
                  for (final row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['', '0', '⌫'],
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.map((k) {
                          if (k.isEmpty) return const SizedBox(width: 72, height: 72);
                          return GestureDetector(
                            onTap: k == '⌫' ? _onDelete : () => _onDigit(k),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: k == '⌫'
                                    ? const Icon(Icons.backspace_outlined,
                                        color: Colors.white60, size: 22)
                                    : Text(k,
                                        style: AppTextStyles.appTitle
                                            .copyWith(fontSize: 26)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
