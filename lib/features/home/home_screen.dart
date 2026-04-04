import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/memory_provider.dart';
import 'widgets/memory_card_stack.dart';
import 'widgets/memory_card_controller.dart';
import 'widgets/bottom_controls.dart';
import 'widgets/empty_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _cardController = MemoryCardController();

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memories = ref.watch(memoriesProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                _AppBar(
                  onSettingsTap: () => context.push('/settings'),
                  onAddTap: () => context.push('/add'),
                  onPixelmapTap: () => context.push('/pixelmap-gallery'),
                ),
                if (memories.isEmpty)
                  const Expanded(child: EmptyState())
                else
                  Expanded(
                    child: MemoryCardStack(
                      memories: memories,
                      controller: _cardController,
                      onCardTap: (memory) =>
                          context.push('/memory/${memory.id}'),
                      onFavourite: (memory) => ref
                          .read(memoriesProvider.notifier)
                          .toggleFavourite(memory.id),
                    ),
                  ),
              ],
            ),
            // Floating bottom controls — fixed over content
            if (memories.isNotEmpty)
              Positioned(
                bottom: bottomPadding + 32,
                left: 0,
                right: 0,
                child: BottomControls(controller: _cardController),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.onSettingsTap,
    required this.onAddTap,
    required this.onPixelmapTap,
  });

  final VoidCallback onSettingsTap;
  final VoidCallback onAddTap;
  final VoidCallback onPixelmapTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(Icons.favorite, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 10),
          Text('harmony', style: AppTextStyles.appTitle),
          const Spacer(),
          // Add button
          GestureDetector(
            onTap: onAddTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.add, color: AppColors.accent, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          // Pixelmap gallery button
          GestureDetector(
            onTap: onPixelmapTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.grid_view_rounded,
                  color: Colors.white54, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          // Settings button
          GestureDetector(
            onTap: onSettingsTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: Colors.white.withValues(alpha: 0.6),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
