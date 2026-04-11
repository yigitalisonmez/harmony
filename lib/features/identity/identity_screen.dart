import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/identity_service.dart';
import '../../core/router/app_router.dart' show routerCoupleNotifier, routerIdentityNotifier;
import '../../data/repositories/couple_provider.dart';

const _personas = ['Berfin', 'Yiğitali'];
const _berfinGif = 'assets/Young_slim_Mediterranean_female_with_long_wavy_dar_breathing-idle_south-east.gif';
const _yigitaliGif = 'assets/Young_brunette_male_with_curly_black_hair_short_be_breathing-idle_west.gif';

class IdentityScreen extends ConsumerStatefulWidget {
  const IdentityScreen({super.key});

  @override
  ConsumerState<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends ConsumerState<IdentityScreen>
    with SingleTickerProviderStateMixin {
  // Step 1 — date code
  final _dateCtrl = TextEditingController();
  bool _dateLoading = false;
  String? _dateError;

  // Step 2 — persona
  String? _selected;
  bool _saving = false;

  // Which step we're on
  bool _dateVerified = false;

  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  // ── Step 1 ────────────────────────────────────────────────────────────────

  Future<void> _submitDate() async {
    FocusScope.of(context).unfocus();
    final input = _dateCtrl.text.trim();
    if (input.length != 6) {
      setState(() => _dateError = 'Enter your start date — e.g. 210925');
      return;
    }
    setState(() { _dateLoading = true; _dateError = null; });
    try {
      if (AuthService.currentUser == null) await AuthService.signInAnonymously();
      final coupleId = await AuthService.loginWithCode(input);
      ref.read(coupleIdProvider.notifier).state = coupleId;
      routerCoupleNotifier.value = coupleId;
      _fadeCtrl.reverse().then((_) {
        setState(() { _dateVerified = true; _dateLoading = false; });
        _fadeCtrl.forward();
      });
    } catch (e) {
      String msg = 'Something went wrong. Try again.';
      if (e.toString().contains('wrong_code')) msg = 'Wrong date — try again.';
      if (e.toString().contains('couple_not_found')) msg = 'Couple not found.';
      setState(() { _dateError = msg; _dateLoading = false; });
    }
  }

  // ── Step 2 ────────────────────────────────────────────────────────────────

  void _select(String name) {
    HapticFeedback.lightImpact();
    setState(() => _selected = name);
  }

  Future<void> _confirm() async {
    if (_selected == null || _saving) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    final coupleId = ref.read(coupleIdProvider);
    if (coupleId != null) await AuthService.setName(coupleId, _selected!);
    await IdentityService.setName(_selected!);
    ref.read(myNameProvider.notifier).state = _selected!;
    if (mounted) {
      routerIdentityNotifier.value = true;
      context.go('/');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeCtrl,
          child: _dateVerified ? _buildPersonaPicker() : _buildDateStep(),
        ),
      ),
    );
  }

  // ── Date step ─────────────────────────────────────────────────────────────

  Widget _buildDateStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        28, 64, 28,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Logo(),
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
            style: AppTextStyles.body.copyWith(color: Colors.white54, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _dateCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.bodyBold.copyWith(fontSize: 28, letterSpacing: 8),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'DDMMYY',
              hintStyle: AppTextStyles.body.copyWith(
                fontSize: 16, letterSpacing: 2, color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
            onSubmitted: (_) => _submitDate(),
          ),
          if (_dateError != null) ...[
            const SizedBox(height: 12),
            Text(_dateError!,
                style: AppTextStyles.body.copyWith(color: Colors.redAccent, fontSize: 12)),
          ],
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _dateLoading ? null : _submitDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: _dateLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Continue',
                        style: AppTextStyles.bodyBold.copyWith(color: Colors.white, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Persona picker ────────────────────────────────────────────────────────

  Widget _buildPersonaPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Logo(),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('oh, you\'re back 🤍',
                      style: AppTextStyles.appTitle.copyWith(fontSize: 22)),
                  const SizedBox(height: 2),
                  Text('which one of you snuck in?',
                      style: AppTextStyles.muted.copyWith(fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Side-by-side cards
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _IdentityCard(
                    name: _personas[0], // Berfin
                    subtitle: 'the one worth\nevery effort',
                    gifPath: _berfinGif,
                    isSelected: _selected == _personas[0],
                    anySelected: _selected != null,
                    onTap: () => _select(_personas[0]),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _IdentityCard(
                    name: _personas[1], // Yiğitali
                    subtitle: 'secretly the\nromantic one',
                    gifPath: _yigitaliGif,
                    isSelected: _selected == _personas[1],
                    anySelected: _selected != null,
                    onTap: () => _select(_personas[1]),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Continue button
          AnimatedOpacity(
            opacity: _selected != null ? 1.0 : 0.35,
            duration: const Duration(milliseconds: 250),
            child: GestureDetector(
              onTap: _confirm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _selected != null ? 'that\'s me, let\'s go ♥' : 'pick one first',
                          style: AppTextStyles.bodyBold.copyWith(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }
}

// ── Identity Card ─────────────────────────────────────────────────────────────

class _IdentityCard extends StatefulWidget {
  const _IdentityCard({
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.anySelected,
    required this.onTap,
    this.gifPath,
  });

  final String name;
  final String subtitle;
  final bool isSelected;
  final bool anySelected;
  final VoidCallback onTap;
  final String? gifPath;

  @override
  State<_IdentityCard> createState() => _IdentityCardState();
}

class _IdentityCardState extends State<_IdentityCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _scale = Tween<double>(begin: 1.0, end: 1.04)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _glow = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_IdentityCard old) {
    super.didUpdateWidget(old);
    if (widget.isSelected && !old.isSelected) _ctrl.forward();
    if (!widget.isSelected && old.isSelected) _ctrl.reverse();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dimmed = widget.anySelected && !widget.isSelected;
    return AnimatedOpacity(
      opacity: dimmed ? 0.25 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12 + 0.55 * _glow.value),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22 * _glow.value),
                    blurRadius: 36 * _glow.value,
                    spreadRadius: 2 * _glow.value,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    widget.gifPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              widget.gifPath!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.25 + 0.45 * _glow.value),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                widget.name[0].toUpperCase(),
                                style: AppTextStyles.appTitle.copyWith(
                                    fontSize: 30, color: AppColors.primary),
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    Text(widget.name,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 17)),
                    const SizedBox(height: 6),
                    Text(widget.subtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.muted.copyWith(
                            fontSize: 11, height: 1.5,
                            color: Colors.white.withValues(alpha: 0.35))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Logo ──────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 20),
          ],
        ),
        child: const Icon(Icons.favorite_rounded, color: Colors.black, size: 24),
      );
}
