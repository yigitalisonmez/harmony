import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
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
    required this.onDelete,
    required this.onReaction,
    this.controller,
  });

  final List<Memory> memories;
  final ValueChanged<Memory> onCardTap;
  final ValueChanged<Memory> onFavourite;
  final ValueChanged<Memory> onDelete;
  final Future<void> Function(String memoryId, String? reaction) onReaction;
  final MemoryCardController? controller;

  @override
  State<MemoryCardStack> createState() => _MemoryCardStackState();
}

class _MemoryCardStackState extends State<MemoryCardStack> {
  int _currentIndex = 0;
  bool _showHeart = false;
  late final CardStackSwiperController _swiperCtrl;

  @override
  void initState() {
    super.initState();
    _swiperCtrl = CardStackSwiperController();
    _register();
  }

  @override
  void didUpdateWidget(MemoryCardStack old) {
    super.didUpdateWidget(old);
    if (widget.controller != old.controller) _register();
  }

  void _register() {
    widget.controller?.register(
      onSkip: () => _swiperCtrl.swipe(CardStackSwiperDirection.left),
      onFavourite: () {
        final idx = _currentIndex.clamp(0, widget.memories.length - 1);
        widget.onFavourite(widget.memories[idx]);
        _swiperCtrl.swipe(CardStackSwiperDirection.right);
      },
    );
  }

  @override
  void dispose() {
    _swiperCtrl.dispose();
    super.dispose();
  }

  // ── Long press options ────────────────────────────────────────────────────
  void _showOptions(BuildContext context, Memory memory) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onDelete(memory);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text('Delete memory',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Cancel',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final memories = widget.memories;
    if (memories.isEmpty) return const SizedBox.shrink();

    final safeIndex = _currentIndex.clamp(0, memories.length - 1);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Card swiper ──────────────────────────────────────────
                CardStackSwiper(
                  controller: _swiperCtrl,
                  cardsCount: memories.length,

                  onSwipe: (previousIndex, currentIndex, direction) {
                    if (direction == CardStackSwiperDirection.right) {
                      widget.onFavourite(memories[previousIndex]);
                    }
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _currentIndex = currentIndex ?? 0;
                    });
                    return true;
                  },
                  cardBuilder: (context, index, percentX, percentY) {
                    final memory = memories[index];
                    return RepaintBoundary(
                      child: GestureDetector(
                        onTap: () => widget.onCardTap(memory),
                        onDoubleTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onFavourite(memory);
                          setState(() => _showHeart = true);
                        },
                        onLongPress: () => _showOptions(context, memory),
                        child: _CardContent(memory: memory),
                      ),
                    );
                  },
                ),

                // ── Heart burst (çift tıkta) ─────────────────────────────
                if (_showHeart)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: _HeartBurst(
                          onComplete: () {
                            if (mounted) setState(() => _showHeart = false);
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Note + hint ──────────────────────────────────────────────────
        _buildNoteSection(memories[safeIndex]),
        const SizedBox(height: 12),
        _buildHint(),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.arrow_back_ios_rounded,
            size: 9, color: Colors.white.withValues(alpha: 0.18)),
        const SizedBox(width: 4),
        Text('skip',
            style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.18),
                letterSpacing: 0.8)),
        const SizedBox(width: 20),
        Icon(Icons.circle,
            size: 4, color: Colors.white.withValues(alpha: 0.12)),
        const SizedBox(width: 20),
        Text('favourite',
            style: TextStyle(
                fontSize: 10,
                color: AppColors.primary.withValues(alpha: 0.45),
                letterSpacing: 0.8)),
        const SizedBox(width: 4),
        Icon(Icons.arrow_forward_ios_rounded,
            size: 9, color: AppColors.primary.withValues(alpha: 0.45)),
      ],
    );
  }

  void _showReactionSheet(BuildContext context, Memory memory) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReactionSheet(
        initialReaction: memory.partnerReaction,
        onSave: (reaction) => widget.onReaction(memory.id, reaction),
      ),
    );
  }

  Widget _buildNoteSection(Memory memory) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (memory.note != null && memory.note!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24, height: 24,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.notes, color: Colors.black, size: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('"${memory.note!}"',
                      style: AppTextStyles.noteText),
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
              Expanded(
                child: Text(
                  timeago.format(memory.createdAt).toUpperCase(),
                  style: AppTextStyles.muted,
                ),
              ),
              // ── Partner reaction ────────────────────────────────────
              GestureDetector(
                onTap: () => _showReactionSheet(context, memory),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: memory.partnerReaction != null &&
                          memory.partnerReaction!.isNotEmpty
                      ? Container(
                          key: ValueKey(memory.partnerReaction),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                memory.partnerReaction!,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          key: const ValueKey('empty'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_reaction_outlined,
                                  size: 12,
                                  color: Colors.white.withValues(alpha: 0.3)),
                              const SizedBox(width: 4),
                              Text(
                                'react',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.3),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Card content ──────────────────────────────────────────────────────────────
class _CardContent extends StatelessWidget {
  const _CardContent({required this.memory});
  final Memory memory;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('MMM dd, yyyy').format(memory.date).toUpperCase();
    return AspectRatio(
      aspectRatio: 3.5 / 4.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _MemoryPhoto(photoPath: memory.photoPath, photoUrl: memory.photoUrl),
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
              top: 20, left: 20,
              child: FrostedBadge(
                icon: Icons.calendar_today_outlined,
                label: dateStr,
              ),
            ),
            if (memory.isFavourite)
              Positioned(
                top: 20, right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            if (memory.location != null && memory.location!.isNotEmpty)
              Positioned(
                bottom: 20, left: 20,
                child: FrostedBadge(
                  icon: Icons.location_on_outlined,
                  label: memory.location!,
                ),
              ),
            if (memory.pixelMap != null &&
                memory.pixelMap!.length == kPixelMapTotal)
              Positioned(
                bottom: 16, right: 16,
                child: _PixelMapBadge(pixels: memory.pixelMap!),
              ),
          ],
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
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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

class _MemoryPhoto extends StatefulWidget {
  const _MemoryPhoto({required this.photoPath, required this.photoUrl});
  final String photoPath;
  final String? photoUrl;

  @override
  State<_MemoryPhoto> createState() => _MemoryPhotoState();
}

class _MemoryPhotoState extends State<_MemoryPhoto> {
  late bool _localExists;
  late File _file;

  @override
  void initState() {
    super.initState();
    _file = File(widget.photoPath);
    _localExists = widget.photoPath.isNotEmpty && _file.existsSync();
  }

  @override
  void didUpdateWidget(_MemoryPhoto old) {
    super.didUpdateWidget(old);
    if (old.photoPath != widget.photoPath) {
      _file = File(widget.photoPath);
      _localExists = widget.photoPath.isNotEmpty && _file.existsSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Local file takes priority (just uploaded), then remote URL
    if (_localExists) {
      return Image.file(_file, fit: BoxFit.cover, cacheWidth: 800);
    }
    if (widget.photoUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.photoUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 800,
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
              color: Colors.white24, size: 48),
        ),
      );
}

// ── Heart burst animation ─────────────────────────────────────────────────────
class _HeartBurst extends StatefulWidget {
  const _HeartBurst({required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<_HeartBurst> createState() => _HeartBurstState();
}

class _HeartBurstState extends State<_HeartBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.25)
          .chain(CurveTween(curve: Curves.easeOut)), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0)
          .chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4)
          .chain(CurveTween(curve: Curves.easeOut)), weight: 25),
    ]).animate(_ctrl);

    _opacity = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeIn)), weight: 35),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Icon(
            Icons.favorite_rounded,
            size: 100,
            color: AppColors.primary,
            shadows: [
              Shadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reaction input sheet ──────────────────────────────────────────────────────
class _ReactionSheet extends StatefulWidget {
  const _ReactionSheet({
    required this.initialReaction,
    required this.onSave,
  });

  final String? initialReaction;
  final Future<void> Function(String? reaction) onSave;

  @override
  State<_ReactionSheet> createState() => _ReactionSheetState();
}

class _ReactionSheetState extends State<_ReactionSheet> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  static const _quickEmojis = [
    '❤️', '🥰', '😍', '🥲', '😂',
    '✨', '🔥', '💫', '💕', '🫶',
    '😭', '🤩', '😘', '💝', '🌸',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialReaction ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    setState(() => _saving = true);
    await widget.onSave(text.isEmpty ? null : text);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    await widget.onSave(null);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.add_reaction_outlined,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'leave a reaction',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (widget.initialReaction != null &&
                      widget.initialReaction!.isNotEmpty)
                    GestureDetector(
                      onTap: _saving ? null : _clear,
                      child: Text(
                        'remove',
                        style: TextStyle(
                          color: Colors.redAccent.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: _quickEmojis.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final emoji = _quickEmojis[i];
                  final selected = _ctrl.text == emoji;
                  return GestureDetector(
                    onTap: () {
                      _ctrl.text = emoji;
                      _ctrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: emoji.length),
                      );
                      setState(() {});
                    },
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _ctrl,
                maxLength: 60,
                maxLines: 1,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'or type something sweet… ♡',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 14,
                  ),
                  counterStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 11,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: _ctrl.text.trim().isEmpty
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            'send reaction ♡',
                            style: TextStyle(
                              color: _ctrl.text.trim().isEmpty
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
