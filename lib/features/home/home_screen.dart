import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/memory_provider.dart';
import '../../data/repositories/settings_provider.dart';
import 'widgets/memory_card_stack.dart';
import 'widgets/memory_card_controller.dart';
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
    final memoriesAsync = ref.watch(memoriesProvider);
    final memories = memoriesAsync.valueOrNull;
    final daysCount = ref.watch(settingsProvider).daysCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AppBar(
              daysCount: daysCount,
              onAddTap: () => context.push('/add'),
              onExploreTap: () => context.push('/explore'),
            ),
            // Loading state → shimmer
            if (memories == null)
              const Expanded(child: _CardShimmer())
            else if (memories.isEmpty)
              const Expanded(child: EmptyState())
            else
              Expanded(
                child: MemoryCardStack(
                  memories: memories,
                  controller: _cardController,
                  onCardTap: (memory) =>
                      context.push('/memory/${memory.id}'),
                  onFavourite: (memory) => ref
                      .read(memoriesNotifierProvider)
                      .toggleFavourite(memory.id),
                  onDelete: (memory) => ref
                      .read(memoriesNotifierProvider)
                      .delete(memory.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Card shimmer ──────────────────────────────────────────────────────────────
class _CardShimmer extends StatelessWidget {
  const _CardShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF1A1A1A),
        highlightColor: const Color(0xFF2A2A2A),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Back card 2
            Positioned(
              top: 16,
              child: Transform.scale(
                scale: 0.92,
                child: _shimmerCard(),
              ),
            ),
            // Back card 1
            Positioned(
              top: 8,
              child: Transform.scale(
                scale: 0.96,
                child: _shimmerCard(),
              ),
            ),
            // Front card
            _shimmerCard(),
          ],
        ),
      ),
    );
  }

  Widget _shimmerCard() {
    return Container(
      width: double.infinity,
      height: 480,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(28),
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.daysCount,
    required this.onAddTap,
    required this.onExploreTap,
  });

  final int? daysCount;
  final VoidCallback onAddTap;
  final VoidCallback onExploreTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          // Title + days
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('harmony', style: AppTextStyles.appTitle),
              if (daysCount != null)
                Text(
                  '$daysCount days together ♡',
                  style: AppTextStyles.muted.copyWith(
                    fontSize: 10,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
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
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.add, color: AppColors.accent, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          // Explore button
          GestureDetector(
            onTap: onExploreTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Icon(
                Icons.apps_rounded,
                color: Colors.white.withValues(alpha: 0.55),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
