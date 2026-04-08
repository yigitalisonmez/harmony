import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/memory.dart';
import '../../data/repositories/memory_provider.dart';
import '../../shared/widgets/frosted_badge.dart';
import '../../core/utils/pixel_map_generator.dart';
import '../../shared/widgets/pixel_map_widget.dart';

class MemoryDetailScreen extends ConsumerWidget {
  const MemoryDetailScreen({super.key, required this.memoryId});

  final String memoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(memoriesProvider).valueOrNull ?? [];
    final memory = memories.where((m) => m.id == memoryId).firstOrNull;

    if (memory == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Memory not found', style: AppTextStyles.body),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _DetailContent(memory: memory),
    );
  }
}

class _DetailContent extends ConsumerStatefulWidget {
  const _DetailContent({required this.memory});

  final Memory memory;

  @override
  ConsumerState<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends ConsumerState<_DetailContent> {
  late bool _isFavourite;

  @override
  void initState() {
    super.initState();
    _isFavourite = widget.memory.isFavourite;
  }

  Future<void> _toggleFavourite() async {
    HapticFeedback.mediumImpact();
    setState(() => _isFavourite = !_isFavourite);
    await ref.read(memoriesNotifierProvider).toggleFavourite(widget.memory.id);
  }

  void _confirmDelete(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.delete_outline, color: Color(0xFFFF3B30), size: 40),
              const SizedBox(height: 16),
              Text('Delete this memory?',
                  style: AppTextStyles.appTitle.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                "This can't be undone.",
                style: AppTextStyles.body.copyWith(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text('Cancel', style: AppTextStyles.bodyBold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        ref
                            .read(memoriesNotifierProvider)
                            .delete(widget.memory.id);
                        context.go('/');
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFF3B30).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              fontFamily: 'Figtree',
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF3B30),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    final dateStr = DateFormat('MMMM dd, yyyy').format(memory.date).toUpperCase();

    return CustomScrollView(
      slivers: [
        // Photo header
        SliverToBoxAdapter(
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: _buildPhoto(memory),
              ),
              // Gradient overlay at bottom of photo
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 120,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
              ),
              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
              // Delete button
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 16,
                child: GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white70, size: 20),
                  ),
                ),
              ),
              // Date badge overlay
              Positioned(
                bottom: 70,
                left: 20,
                child: FrostedBadge(
                  icon: Icons.calendar_today_outlined,
                  label: dateStr,
                ),
              ),
              if (memory.location != null && memory.location!.isNotEmpty)
                Positioned(
                  bottom: 30,
                  left: 20,
                  child: FrostedBadge(
                    icon: Icons.location_on_outlined,
                    label: memory.location!,
                  ),
                ),
            ],
          ),
        ),
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Favourite toggle
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time_outlined,
                                  size: 13, color: Colors.white.withValues(alpha: 0.35)),
                              const SizedBox(width: 6),
                              Text(
                                'ADDED ${timeago.format(memory.createdAt).toUpperCase()}',
                                style: AppTextStyles.muted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleFavourite,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isFavourite
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isFavourite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavourite ? AppColors.primary : Colors.white38,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                // Pixelmap section
                if (memory.pixelMap != null && memory.pixelMap!.length == kPixelMapTotal) ...[
                  const SizedBox(height: 28),
                  _PixelMapSection(pixels: memory.pixelMap!),
                ],
                if (memory.note != null && memory.note!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.notes, color: Colors.black, size: 14),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '"${memory.note!}"',
                          style: AppTextStyles.noteText,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoto(Memory memory) {
    // Local file — own device, shown immediately
    if (memory.photoPath.isNotEmpty) {
      final file = File(memory.photoPath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    // Remote — use cache, instant on repeat visits
    if (memory.photoUrl != null && memory.photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: memory.photoUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: const Color(0xFF1A1A1A)),
        errorWidget: (_, __, ___) => Container(
          color: const Color(0xFF1A1A1A),
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined,
                color: Colors.white24, size: 48),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: Colors.white24, size: 48),
      ),
    );
  }
}

class _PixelMapSection extends StatelessWidget {
  const _PixelMapSection({required this.pixels});

  final List<int> pixels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PIXEL MAP',
              style: AppTextStyles.muted.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              // Large pixelmap
              PixelMapWidget(
                pixels: pixels,
                size: 120,
              ),
              const SizedBox(width: 20),
              // Info text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '8 × 8',
                      style: AppTextStyles.appTitle.copyWith(
                        fontSize: 28,
                        letterSpacing: -1,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '64 pixels\nextracted from\nthis memory.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.mutedForeground,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
