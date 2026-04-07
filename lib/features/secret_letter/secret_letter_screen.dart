import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/settings_provider.dart';

class SecretLetterScreen extends ConsumerStatefulWidget {
  const SecretLetterScreen({super.key});

  @override
  ConsumerState<SecretLetterScreen> createState() =>
      _SecretLetterScreenState();
}

class _SecretLetterScreenState extends ConsumerState<SecretLetterScreen> {
  late final TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: ref.read(settingsProvider).letter);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(settingsProvider.notifier).setLetter(_ctrl.text);
    if (!mounted) return;
    setState(() => _editing = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final empty = _ctrl.text.trim().isEmpty && !_editing;

    return Scaffold(
      backgroundColor: const Color(0xFF060606),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  GestureDetector(
                    onTap: _editing ? _save : () => setState(() => _editing = true),
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
                      child: Text(
                        _editing ? 'Save' : 'Edit',
                        style: AppTextStyles.body.copyWith(
                          color:
                              _editing ? AppColors.primary : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(Icons.mail_outline_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text('secret letter',
                      style: AppTextStyles.appTitle.copyWith(fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _editing
                    ? TextField(
                        controller: _ctrl,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        autofocus: true,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 18,
                          height: 1.85,
                        ),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Write your letter here...',
                          hintStyle: GoogleFonts.playfairDisplay(
                            color: Colors.white24,
                            fontSize: 18,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          empty
                              ? 'No letter yet.\nTap Edit to write one.'
                              : _ctrl.text,
                          style: GoogleFonts.playfairDisplay(
                            color: empty
                                ? Colors.white24
                                : Colors.white.withValues(alpha: 0.88),
                            fontSize: 18,
                            height: 1.85,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
