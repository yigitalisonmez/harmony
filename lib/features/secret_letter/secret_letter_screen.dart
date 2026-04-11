import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/letter_provider.dart';

class SecretLetterScreen extends ConsumerStatefulWidget {
  const SecretLetterScreen({super.key});

  @override
  ConsumerState<SecretLetterScreen> createState() => _SecretLetterScreenState();
}

class _SecretLetterScreenState extends ConsumerState<SecretLetterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final TextEditingController _ctrl;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _ctrl = TextEditingController();
    // Populate controller once my letter loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final myLetter = ref.read(myLetterProvider).valueOrNull;
      if (myLetter != null && myLetter.isNotEmpty) {
        _ctrl.text = myLetter;
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(letterNotifierProvider).save(_ctrl.text.trim());
      if (!mounted) return;
      setState(() => _editing = false);
      FocusScope.of(context).unfocus();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myLetterAsync = ref.watch(myLetterProvider);
    final partnerLetterAsync = ref.watch(partnerLetterProvider);
    final partnerUidAsync = ref.watch(partnerUidProvider);

    // Sync controller text when letter first arrives (only if not editing)
    ref.listen(myLetterProvider, (_, next) {
      if (!_editing && next.valueOrNull != null && _ctrl.text.isEmpty) {
        _ctrl.text = next.valueOrNull!;
      }
    });

    final partnerJoined = partnerUidAsync.valueOrNull != null;

    return Scaffold(
      backgroundColor: const Color(0xFF060606),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
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
                  const Spacer(),
                  // Save / Edit button — only shown on "my letter" tab
                  AnimatedBuilder(
                    animation: _tab,
                    builder: (_, __) => _tab.index == 0
                        ? GestureDetector(
                            onTap: _saving
                                ? null
                                : (_editing
                                    ? _save
                                    : () => setState(() => _editing = true)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 9),
                              decoration: BoxDecoration(
                                color: _editing
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _editing
                                      ? AppColors.primary.withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: _saving
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : Text(
                                      _editing ? 'Save' : 'Edit',
                                      style: AppTextStyles.body.copyWith(
                                        color: _editing
                                            ? AppColors.primary
                                            : Colors.white60,
                                      ),
                                    ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ── Icon + title ─────────────────────────────────────────
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.mail_outline_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 10),
            Text('secret letter',
                style: AppTextStyles.appTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 24),
            // ── Tabs ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tab,
                  onTap: (_) {
                    if (_editing) {
                      setState(() => _editing = false);
                      FocusScope.of(context).unfocus();
                    }
                    setState(() {});
                  },
                  indicator: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: AppTextStyles.body.copyWith(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle:
                      AppTextStyles.body.copyWith(fontSize: 13),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.white38,
                  tabs: const [
                    Tab(text: 'my letter'),
                    Tab(text: 'their letter'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ── Tab content ──────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tab,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // ── My letter ──────────────────────────────────────
                  _LetterPane(
                    editing: _editing,
                    controller: _ctrl,
                    asyncValue: myLetterAsync,
                    emptyHint: 'Write something for them...\n\nTap Edit to begin.',
                  ),
                  // ── Their letter ───────────────────────────────────
                  partnerJoined
                      ? _LetterPane(
                          editing: false,
                          controller: null,
                          asyncValue: partnerLetterAsync,
                          emptyHint:
                              'maybe they\'re too busy loving you\nto find the right words yet ♡',
                          readOnly: true,
                        )
                      : _PartnerNotJoined(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Letter pane ───────────────────────────────────────────────────────────────
class _LetterPane extends StatelessWidget {
  const _LetterPane({
    required this.editing,
    required this.controller,
    required this.asyncValue,
    required this.emptyHint,
    this.readOnly = false,
  });

  final bool editing;
  final TextEditingController? controller;
  final AsyncValue<String?> asyncValue;
  final String emptyHint;
  final bool readOnly;

  static final _letterStyle = GoogleFonts.playfairDisplay(
    color: Colors.white.withValues(alpha: 0.88),
    fontSize: 18,
    height: 1.85,
  );

  static final _hintStyle = GoogleFonts.playfairDisplay(
    color: Colors.white24,
    fontSize: 16,
    height: 1.8,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: asyncValue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary),
        ),
        error: (_, __) => Center(
          child: Text('Could not load letter.',
              style: _hintStyle, textAlign: TextAlign.center),
        ),
        data: (content) {
          final isEmpty = content == null || content.trim().isEmpty;

          if (editing && controller != null) {
            return TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              autofocus: true,
              style: _letterStyle,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Write your letter here...',
                hintStyle: _hintStyle,
              ),
            );
          }

          return SingleChildScrollView(
            child: Text(
              isEmpty ? emptyHint : content,
              style: isEmpty ? _hintStyle : _letterStyle,
              textAlign: isEmpty ? TextAlign.center : TextAlign.start,
            ),
          );
        },
      ),
    );
  }
}

// ── Partner not joined yet ────────────────────────────────────────────────────
class _PartnerNotJoined extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_outlined,
                color: Colors.white.withValues(alpha: 0.2), size: 44),
            const SizedBox(height: 16),
            Text(
              'Waiting for your partner\nto join. ♡',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white24,
                fontSize: 16,
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
