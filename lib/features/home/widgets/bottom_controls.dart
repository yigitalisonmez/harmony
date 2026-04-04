import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'memory_card_controller.dart';

class BottomControls extends StatelessWidget {
  const BottomControls({super.key, required this.controller});

  final MemoryCardController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Dismiss — plain icon, very transparent
        GestureDetector(
          onTap: controller.skip,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.close,
              color: Colors.white.withValues(alpha: 0.22),
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 56),
        // Heart — 96px circle with blur glow behind
        _HeartButton(onTap: controller.favourite),
        const SizedBox(width: 56),
        // Share — plain icon, very transparent
        GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.ios_share,
              color: Colors.white.withValues(alpha: 0.22),
              size: 32,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeartButton extends StatefulWidget {
  const _HeartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<_HeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Blur glow layer (primary/50, blur 40)
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              // Button circle
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.black,
                  size: 44,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
