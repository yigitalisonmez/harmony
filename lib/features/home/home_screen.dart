import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/streak_calculator.dart';
import '../../data/models/memory.dart';
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
  void initState() {
    super.initState();
    // Navigate to memory if app was opened via notification tap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = NotificationService.pendingRoute;
      if (route != null && mounted) {
        NotificationService.pendingRoute = null;
        context.push(route);
      }
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  void _showRandomMemory(BuildContext context, List<Memory> memories) {
    HapticFeedback.mediumImpact();
    final memory = memories[Random().nextInt(memories.length)];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RandomMemorySheet(
        memory: memory,
        onViewDetail: () {
          Navigator.pop(context);
          context.push('/memory/${memory.id}');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(memoriesProvider);
    final memories = memoriesAsync.valueOrNull;
    final daysCount = ref.watch(settingsProvider).daysCount;
    final streak = memories != null ? calculateStreak(memories) : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AppBar(
              daysCount: daysCount,
              streak: streak,
              onAddTap: () => context.push('/add'),
              onExploreTap: () => context.push('/explore'),
              onRandomTap: memories != null && memories.isNotEmpty
                  ? () => _showRandomMemory(context, memories)
                  : null,
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
                  onReaction: (id, reaction) => ref
                      .read(memoriesNotifierProvider)
                      .updateReaction(id, reaction),
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
    required this.streak,
    required this.onAddTap,
    required this.onExploreTap,
    required this.onRandomTap,
  });

  final int? daysCount;
  final int streak;
  final VoidCallback onAddTap;
  final VoidCallback onExploreTap;
  final VoidCallback? onRandomTap;

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
          // Title + days + streak
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('harmony', style: AppTextStyles.appTitle),
                  if (streak > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              color: Color(0xFFFF6B35), size: 11),
                          const SizedBox(width: 2),
                          Text(
                            '$streak',
                            style: const TextStyle(
                              color: Color(0xFFFF6B35),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (daysCount != null)
                Text(
                  '$daysCount days of us ♡',
                  style: AppTextStyles.muted.copyWith(
                    fontSize: 10,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          const Spacer(),
          // Random memory button
          if (onRandomTap != null) ...[
            GestureDetector(
              onTap: onRandomTap,
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
                  Icons.shuffle_rounded,
                  color: Colors.white.withValues(alpha: 0.55),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
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

// ── Random memory bottom sheet ────────────────────────────────────────────────
class _RandomMemorySheet extends StatefulWidget {
  const _RandomMemorySheet({
    required this.memory,
    required this.onViewDetail,
  });

  final Memory memory;
  final VoidCallback onViewDetail;

  @override
  State<_RandomMemorySheet> createState() => _RandomMemorySheetState();
}

class _RandomMemorySheetState extends State<_RandomMemorySheet> {
  late bool _localExists;
  late File _file;

  @override
  void initState() {
    super.initState();
    _file = File(widget.memory.photoPath);
    _localExists =
        widget.memory.photoPath.isNotEmpty && _file.existsSync();
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    final dateStr =
        DateFormat('MMMM dd, yyyy').format(memory.date);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // "remember this?" header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primary.withValues(alpha: 0.8), size: 16),
                const SizedBox(width: 6),
                Text(
                  'remember this?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Photo preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: _buildPhoto(memory),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Date
            Text(
              dateStr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            // Note preview
            if (memory.note != null && memory.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '"${memory.note!}"',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // View detail button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: widget.onViewDetail,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_rounded,
                          color: Colors.black, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'view memory',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Dismiss
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'maybe later',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(Memory memory) {
    if (_localExists) {
      return Image.file(_file, fit: BoxFit.cover, cacheWidth: 600);
    }
    if (memory.photoUrl != null) {
      return CachedNetworkImage(
        imageUrl: memory.photoUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 600,
        placeholder: (_, __) => Container(color: const Color(0xFF1A1A1A)),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF1A1A1A),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: Colors.white24, size: 40),
        ),
      );
}
