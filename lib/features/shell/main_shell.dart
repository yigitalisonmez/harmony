import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../bucket_list/bucket_list_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── Home ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: h,
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: const HomeScreen(),
              ),
            ),
          ),

          // ── Divider hint ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionDivider(label: 'explore'),
          ),

          // ── Explore ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              child: const ExploreScreen(),
            ),
          ),

          // ── Divider hint ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionDivider(label: 'bucket list'),
          ),

          // ── Bucket List ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: h,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: const BucketListScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.white.withValues(alpha: 0.06)),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.18),
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ],
      ),
    );
  }
}
