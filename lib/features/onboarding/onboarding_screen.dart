import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/auth_service.dart';
import '../../data/repositories/couple_provider.dart';
import '../../core/router/app_router.dart' show routerCoupleNotifier;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _dateCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _dateCtrl.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String input) {
    final s = input.trim();
    if (s.length != 6) return null;
    final day   = int.tryParse(s.substring(0, 2));
    final month = int.tryParse(s.substring(2, 4));
    final year  = int.tryParse('20${s.substring(4, 6)}');
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  Future<void> _getStarted() async {
    FocusScope.of(context).unfocus();
    final input = _dateCtrl.text.trim();
    final date  = _parseDate(input);
    if (date == null) {
      setState(() => _error = 'Enter your start date — e.g. 220925');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      // Ensure anonymous sign-in is complete
      if (AuthService.currentUser == null) {
        await AuthService.signInAnonymously();
      }

      final coupleId = await AuthService.joinOrCreateCouple(
        code: input,
        startDate: date,
      );
      ref.read(coupleIdProvider.notifier).state = coupleId;
      routerCoupleNotifier.value = coupleId; // triggers router redirect → '/'
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            28, 64, 28,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heart logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.black, size: 24),
              ),

              const SizedBox(height: 20),
              Text('harmony',
                  style: AppTextStyles.appTitle.copyWith(fontSize: 36)),
              const SizedBox(height: 6),
              Text('your memories, together', style: AppTextStyles.muted),

              const SizedBox(height: 56),

              Text('When did you two start?',
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                'This date is your shared key — both of you enter it to connect.',
                style: AppTextStyles.body
                    .copyWith(color: Colors.white54, height: 1.5),
              ),

              const SizedBox(height: 20),

              // Date input
              TextField(
                controller: _dateCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 28, letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'your start date',
                  hintStyle: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    letterSpacing: 1,
                    color: Colors.white24,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 20),
                  suffixText: 'DDMMYY',
                  suffixStyle:
                      AppTextStyles.muted.copyWith(fontSize: 10),
                ),
                onSubmitted: (_) => _getStarted(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: AppTextStyles.body
                        .copyWith(color: Colors.redAccent, fontSize: 12)),
              ],

              const SizedBox(height: 32),

              // CTA button
              GestureDetector(
                onTap: _loading ? null : _getStarted,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text('Get started',
                            style: AppTextStyles.bodyBold.copyWith(
                                color: Colors.white, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
