import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/memory.dart';
import '../../../shared/widgets/frosted_badge.dart';
import '../../../core/utils/pixel_map_generator.dart';
import '../../../shared/widgets/pixel_map_widget.dart';
import 'memory_card_controller.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class MemoryCardStack extends StatefulWidget {
  const MemoryCardStack({
    super.key,
    required this.memories,
    required this.onCardTap,
    required this.onFavourite,
    this.controller,
  });

  final List<Memory> memories;
  final ValueChanged<Memory> onCardTap;
  final ValueChanged<Memory> onFavourite;
  final MemoryCardController? controller;

  @override
  State<MemoryCardStack> createState() => _MemoryCardStackState();
}

class _MemoryCardStackState extends State<MemoryCardStack>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    );
    widget.controller?.register(
      onSkip: _flipToNext,
      onFavourite: _favouriteAndFlip,
    );
  }

  @override
  void didUpdateWidget(MemoryCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      widget.controller?.register(
        onSkip: _flipToNext,
        onFavourite: _favouriteAndFlip,
      );
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Memory get _currentMemory => widget.memories[_currentIndex];
  Memory get _nextMemory =>
      widget.memories[(_currentIndex + 1) % widget.memories.length];

  void _flipToNext() {
    if (_flipController.isAnimating) return;
    HapticFeedback.mediumImpact();
    _flipController.forward(from: 0).then((_) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.memories.length;
      });
      _flipController.reset();
    });
  }

  void _favouriteAndFlip() {
    if (_flipController.isAnimating) return;
    widget.onFavourite(_currentMemory);
    _flipToNext();
  }

  @override
  Widget build(BuildContext context) {
    final memories = widget.memories;
    if (memories.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Back card — always the next memory, peeks behind
                _buildBackCard(_nextMemory),
                // Front card — 3D flip animation
                _buildFlipCard(),
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, _) {
            // Cross-fade note section during flip
            final v = _flipAnimation.value;
            final showNext = v >= 0.5;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _buildNoteSection(
                showNext ? _nextMemory : _currentMemory,
                key: ValueKey(showNext ? 'next' : 'current'),
              ),
            );
          },
        ),
        const SizedBox(height: 110),
      ],
    );
  }

  Widget _buildBackCard(Memory memory) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, _) {
        // As flip progresses, back card scales up slightly toward center
        final t = _flipAnimation.value;
        final scale = 0.96 + t * 0.04;
        final rotation = -0.035 + t * 0.035;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateZ(rotation)
            ..scale(scale),
          child: _CardContent(memory: memory, opacity: 0.6 + t * 0.4),
        );
      },
    );
  }

  Widget _buildFlipCard() {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, _) {
        final v = _flipAnimation.value;
        final isFirstHalf = v < 0.5;

        // First half: current card rotates away (0 → π/2)
        // Second half: next card rotates in  (-π/2 → 0)
        final angle = isFirstHalf
            ? v * math.pi          // 0 → π/2
            : (v - 1.0) * math.pi; // -π/2 → 0

        final memory = isFirstHalf ? _currentMemory : _nextMemory;

        return GestureDetector(
          onTap: _flipToNext,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015) // perspective
              ..rotateY(angle),
            child: _CardContent(memory: memory),
          ),
        );
      },
    );
  }

  Widget _buildNoteSection(Memory memory, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (memory.note != null && memory.note!.isNotEmpty) ...[
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
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Icon(Icons.access_time_outlined,
                  size: 14, color: Colors.white.withValues(alpha: 0.35)),
              const SizedBox(width: 6),
              Text(
                timeago.format(memory.createdAt).toUpperCase(),
                style: AppTextStyles.muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.memory, this.opacity = 1.0});

  final Memory memory;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(memory.date).toUpperCase();

    return Opacity(
      opacity: opacity,
      child: AspectRatio(
        aspectRatio: 3.5 / 4.5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _MemoryPhoto(photoPath: memory.photoPath),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: FrostedBadge(
                  icon: Icons.calendar_today_outlined,
                  label: dateStr,
                ),
              ),
              if (memory.location != null && memory.location!.isNotEmpty)
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: FrostedBadge(
                    icon: Icons.location_on_outlined,
                    label: memory.location!,
                  ),
                ),
              if (memory.pixelMap != null &&
                  memory.pixelMap!.length == kPixelMapTotal)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: _PixelMapBadge(pixels: memory.pixelMap!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PixelMapBadge extends StatelessWidget {
  const _PixelMapBadge({required this.pixels});

  final List<int> pixels;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: PixelMapWidget(pixels: pixels, size: 44),
        ),
      ),
    );
  }
}

class _MemoryPhoto extends StatelessWidget {
  const _MemoryPhoto({required this.photoPath});

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    final file = File(photoPath);
    return file.existsSync()
        ? Image.file(file, fit: BoxFit.cover)
        : Container(
            color: const Color(0xFF1A1A1A),
            child: const Center(
              child: Icon(Icons.image_not_supported_outlined,
                  color: Colors.white24, size: 48),
            ),
          );
  }
}
