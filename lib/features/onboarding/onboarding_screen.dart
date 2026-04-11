import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/auth_service.dart';
import '../../core/router/app_router.dart' show routerCoupleNotifier;
import '../../data/repositories/couple_provider.dart';

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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final input = _dateCtrl.text.trim();
    if (input.length != 6) {
      setState(() => _error = 'Enter your start date — e.g. 210925');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      if (AuthService.currentUser == null) {
        await AuthService.signInAnonymously();
      }
      final coupleId = await AuthService.loginWithCode(input);
      ref.read(coupleIdProvider.notifier).state = coupleId;
      routerCoupleNotifier.value = coupleId;
    } catch (e) {
      String msg = 'Something went wrong. Try again.';
      if (e.toString().contains('wrong_code')) msg = 'Wrong date — try again.';
      if (e.toString().contains('couple_not_found')) msg = 'Couple not found.';
      setState(() { _error = msg; _loading = false; });
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
              // Logo
              Container(
                width: 48, height: 48,
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

              Text('When did it all begin?',
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
              const SizedBox(height: 6),
              Text(
                'This date is your shared key — both of you enter it to connect.',
                style: AppTextStyles.body
                    .copyWith(color: Colors.white54, height: 1.5),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _dateCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.bodyBold
                    .copyWith(fontSize: 28, letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'DDMMYY',
                  hintStyle: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    letterSpacing: 2,
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
                ),
                onSubmitted: (_) => _submit(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: AppTextStyles.body
                        .copyWith(color: Colors.redAccent, fontSize: 12)),
              ],

              const SizedBox(height: 32),

              GestureDetector(
                onTap: _loading ? null : _submit,
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
                        : Text('Continue',
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
