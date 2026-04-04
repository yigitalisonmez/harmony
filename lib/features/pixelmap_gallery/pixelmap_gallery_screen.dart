import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/memory.dart';
import '../../data/repositories/memory_provider.dart';
import '../../core/utils/pixel_map_generator.dart';
import '../../shared/widgets/pixel_map_widget.dart';

class PixelmapGalleryScreen extends ConsumerWidget {
  const PixelmapGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(memoriesProvider);
    final withPixelmap = memories
        .where((m) => m.pixelMap != null && m.pixelMap!.length == kPixelMapTotal)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            if (withPixelmap.isEmpty)
              const Expanded(child: _EmptyState())
            else
              Expanded(
                child: _PixelmapGrid(memories: withPixelmap),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pixel Maps',
                  style: AppTextStyles.appTitle.copyWith(fontSize: 20)),
              Text(
                'every memory, 8 × 8',
                style: AppTextStyles.muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PixelmapGrid extends StatelessWidget {
  const _PixelmapGrid({required this.memories});

  final List<Memory> memories;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        return _PixelmapTile(
          memory: memories[index],
          onTap: () => context.push('/memory/${memories[index].id}'),
        );
      },
    );
  }
}

class _PixelmapTile extends StatelessWidget {
  const _PixelmapTile({required this.memory, required this.onTap});

  final Memory memory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd').format(memory.date);
    final year = DateFormat('yyyy').format(memory.date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PixelMapWidget(
              pixels: memory.pixelMap!,
              size: 64,
            ),
            const SizedBox(height: 6),
            Text(
              dateStr.toUpperCase(),
              style: AppTextStyles.muted.copyWith(
                fontSize: 9,
                color: AppColors.foreground,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              year,
              style: AppTextStyles.muted.copyWith(
                fontSize: 8,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 4x4 placeholder pixel grid
            SizedBox(
              width: 64,
              height: 64,
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(16, (i) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            Text('No pixel maps yet',
                style: AppTextStyles.appTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              'Add memories to generate\nyour pixel art collection.',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.mutedForeground, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
