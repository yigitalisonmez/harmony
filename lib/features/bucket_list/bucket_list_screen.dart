import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/places_search_service.dart';
import '../../data/repositories/bucket_list_provider.dart';
import '../../data/repositories/movie_provider.dart';
import '../../data/repositories/places_provider.dart';
import '../../data/repositories/places_repository.dart';

class BucketListScreen extends ConsumerStatefulWidget {
  const BucketListScreen({super.key});

  @override
  ConsumerState<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends ConsumerState<BucketListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items   = ref.watch(bucketListProvider);
    final places  = ref.watch(placesProvider);
    final movies  = ref.watch(moviesProvider);
    final pending = items.where((i) => !i.isCompleted).length;
    final visited = places.where((p) => p.isVisited).length;
    final watched = movies.where((m) => m.isWatched).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
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
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bucket List',
                          style: AppTextStyles.appTitle
                              .copyWith(fontSize: 20)),
                      Text(
                        _tab.index == 0
                            ? '$pending plans left'
                            : _tab.index == 1
                                ? '$visited of ${places.length} visited'
                                : '$watched of ${movies.length} watched',
                        style: AppTextStyles.muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Tabs ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                  unselectedLabelStyle:
                      AppTextStyles.body.copyWith(fontSize: 13),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.white54,
                  tabs: const [
                    Tab(text: 'Plans'),
                    Tab(text: 'Places'),
                    Tab(text: 'Movies'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),

            // ── Tab views ────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _PlansTab(),
                  _PlacesTab(),
                  _MoviesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PLANS TAB (existing bucket list)
// ══════════════════════════════════════════════════════════════════════════════

class _PlansTab extends ConsumerStatefulWidget {
  const _PlansTab();

  @override
  ConsumerState<_PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends ConsumerState<_PlansTab> {
  final _addCtrl  = TextEditingController();
  final _focusNode = FocusNode();
  bool _adding = false;

  @override
  void dispose() {
    _addCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _addCtrl.text.trim();
    if (text.isEmpty) return;
    await ref.read(bucketListProvider.notifier).add(text);
    _addCtrl.clear();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final items   = ref.watch(bucketListProvider);
    final pending = items.where((i) => !i.isCompleted).toList();
    final done    = items.where((i) => i.isCompleted).toList();
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      children: [
        Expanded(
          child: items.isEmpty
              ? _EmptyHint(
                  icon: Icons.checklist_rounded,
                  message: 'Add things you want to\nexperience together.',
                  onAdd: () {
                    setState(() => _adding = true);
                    _focusNode.requestFocus();
                  },
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    ...pending.map((item) => _PlanTile(
                          key: ValueKey(item.id),
                          item: item,
                          onToggle: () {
                            HapticFeedback.mediumImpact();
                            ref
                                .read(bucketListProvider.notifier)
                                .toggle(item.id);
                          },
                          onDelete: () => ref
                              .read(bucketListProvider.notifier)
                              .delete(item.id),
                          onEdit: (t) => ref
                              .read(bucketListProvider.notifier)
                              .updateTitle(item.id, t),
                        )),
                    if (done.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SectionDivider(label: 'COMPLETED (${done.length})'),
                      ...done.map((item) => _PlanTile(
                            key: ValueKey(item.id),
                            item: item,
                            onToggle: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(bucketListProvider.notifier)
                                  .toggle(item.id);
                            },
                            onDelete: () => ref
                                .read(bucketListProvider.notifier)
                                .delete(item.id),
                            onEdit: (t) => ref
                                .read(bucketListProvider.notifier)
                                .updateTitle(item.id, t),
                          )),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
        ),
        // Add bar
        _AddBar(
          ctrl: _addCtrl,
          focusNode: _focusNode,
          isActive: _adding,
          bottomPad: bottomPad,
          onFocus: () => setState(() => _adding = true),
          onSubmit: _submit,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PLACES TAB
// ══════════════════════════════════════════════════════════════════════════════

class _PlacesTab extends ConsumerWidget {
  const _PlacesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places  = ref.watch(placesProvider);
    final pending = places.where((p) => !p.isVisited).toList();
    final visited = places.where((p) => p.isVisited).toList();

    return Stack(
      children: [
        places.isEmpty
            ? _EmptyHint(
                icon: Icons.location_on_outlined,
                message: 'Search for places you want\nto visit together.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  ...pending.map((p) => _PlaceTile(
                        key: ValueKey(p.id),
                        place: p,
                        onToggle: () {
                          HapticFeedback.mediumImpact();
                          ref.read(placesProvider.notifier).toggle(p.id);
                        },
                        onDelete: () =>
                            ref.read(placesProvider.notifier).delete(p.id),
                      )),
                  if (visited.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SectionDivider(label: 'VISITED (${visited.length})'),
                    ...visited.map((p) => _PlaceTile(
                          key: ValueKey(p.id),
                          place: p,
                          onToggle: () {
                            HapticFeedback.lightImpact();
                            ref.read(placesProvider.notifier).toggle(p.id);
                          },
                          onDelete: () =>
                              ref.read(placesProvider.notifier).delete(p.id),
                        )),
                  ],
                ],
              ),

        // FAB — search
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          left: 20,
          right: 20,
          child: GestureDetector(
            onTap: () => _showSearch(context, ref),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text('Search a place',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSearch(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaceSearchSheet(
        onSelected: (place) =>
            ref.read(placesProvider.notifier).add(place),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PLACE SEARCH SHEET  (Google Places Text Search)
// ══════════════════════════════════════════════════════════════════════════════

class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet({required this.onSelected});

  final ValueChanged<PlaceItem> onSelected;

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final _ctrl = TextEditingController();
  List<PlaceResult> _results = [];
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await PlacesSearchService.search(query);
      setState(() => _results = res);
    } on Exception catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _pick(PlaceResult r) {
    final place = PlaceItem(
      id: PlacesRepository.newId(),
      name: r.name,
      address: r.address,
      lat: r.lat,
      lng: r.lng,
      category: r.category,
      rating: r.rating,
      isVisited: false,
      createdAt: DateTime.now(),
    );
    widget.onSelected(place);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Search a place',
              style: AppTextStyles.appTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text('Powered by Google Places',
              style: AppTextStyles.muted.copyWith(fontSize: 11)),
          const SizedBox(height: 16),

          // Search field
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: AppTextStyles.body,
              cursorColor: AppColors.primary,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Mandabatmaz, Neolokal, Karaköy…',
                hintStyle: AppTextStyles.muted,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search,
                            color: AppColors.primary),
                        onPressed: () => _search(_ctrl.text),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Error
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error,
                  style: AppTextStyles.muted
                      .copyWith(color: Colors.redAccent, fontSize: 12)),
            ),

          // Results
          if (_results.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.06)),
                itemBuilder: (_, i) {
                  final r = _results[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                    leading: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _categoryEmoji(r.category),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    title: Text(r.name,
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.categoryLabel.isNotEmpty)
                          Text(r.categoryLabel,
                              style: AppTextStyles.muted.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 11)),
                        Text(r.address,
                            style: AppTextStyles.muted.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    trailing: r.rating != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFCC00), size: 14),
                              const SizedBox(width: 2),
                              Text(r.rating!.toStringAsFixed(1),
                                  style: AppTextStyles.muted
                                      .copyWith(fontSize: 12)),
                            ],
                          )
                        : null,
                    onTap: () => _pick(r),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _categoryEmoji(String? cat) {
    const map = {
      'cafe': '☕',
      'restaurant': '🍽',
      'bar': '🍸',
      'bakery': '🥐',
      'food': '🍴',
      'lodging': '🏨',
      'tourist_attraction': '📍',
      'park': '🌿',
      'museum': '🏛',
      'movie_theater': '🎬',
    };
    return map[cat] ?? '📌';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PLACE TILE
// ══════════════════════════════════════════════════════════════════════════════

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    super.key,
    required this.place,
    required this.onToggle,
    required this.onDelete,
  });

  final PlaceItem place;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  Future<void> _openMaps() async {
    final uri = Uri.parse(place.mapsUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final visited = place.isVisited;

    return Dismissible(
      key: ValueKey(place.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline,
            color: Colors.redAccent, size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: _openMaps,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: visited
                ? Colors.white.withValues(alpha: 0.03)
                : const Color(0xFF111111),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: visited
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            children: [
              // Visited checkbox
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: visited
                        ? AppColors.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: visited
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: visited
                      ? const Icon(Icons.check,
                          color: Colors.black, size: 14)
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: visited
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.9),
                        decoration: visited
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor:
                            Colors.white.withValues(alpha: 0.3),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (place.rating != null) ...[
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFCC00), size: 12),
                          const SizedBox(width: 2),
                          Text(place.rating!.toStringAsFixed(1),
                              style: AppTextStyles.muted.copyWith(fontSize: 11)),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            place.address,
                            style: AppTextStyles.muted.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Maps icon
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.map_outlined,
                    color: AppColors.primary, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PLAN TILE (unchanged logic)
// ══════════════════════════════════════════════════════════════════════════════

class _PlanTile extends StatefulWidget {
  const _PlanTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final BucketItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final ValueChanged<String> onEdit;

  @override
  State<_PlanTile> createState() => _PlanTileState();
}

class _PlanTileState extends State<_PlanTile> {
  bool _editing = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item.title);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _saveEdit() {
    if (_ctrl.text.trim().isNotEmpty) widget.onEdit(_ctrl.text);
    setState(() => _editing = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.item.isCompleted;

    return Dismissible(
      key: ValueKey(widget.item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline,
            color: Colors.redAccent, size: 22),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: GestureDetector(
        onLongPress: () => setState(() => _editing = true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: done
                ? Colors.white.withValues(alpha: 0.03)
                : const Color(0xFF111111),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: done
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: done ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: done
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check,
                          color: Colors.black, size: 14)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _editing
                    ? TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: AppTextStyles.body,
                        cursorColor: AppColors.primary,
                        onEditingComplete: _saveEdit,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : Text(
                        widget.item.title,
                        style: AppTextStyles.body.copyWith(
                          color: done
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.9),
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                          decorationColor:
                              Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MOVIES TAB
// ══════════════════════════════════════════════════════════════════════════════

class _MoviesTab extends ConsumerStatefulWidget {
  const _MoviesTab();

  @override
  ConsumerState<_MoviesTab> createState() => _MoviesTabState();
}

class _MoviesTabState extends ConsumerState<_MoviesTab> {
  final _addCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _adding = false;

  @override
  void dispose() {
    _addCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _addCtrl.text.trim();
    if (text.isEmpty) return;
    await ref.read(moviesProvider.notifier).add(text);
    _addCtrl.clear();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final movies  = ref.watch(moviesProvider);
    final pending = movies.where((m) => !m.isWatched).toList();
    final watched = movies.where((m) => m.isWatched).toList();
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      children: [
        Expanded(
          child: movies.isEmpty
              ? _EmptyHint(
                  icon: Icons.movie_outlined,
                  message: 'Add movies you want to\nwatch together.',
                  onAdd: () {
                    setState(() => _adding = true);
                    _focusNode.requestFocus();
                  },
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    ...pending.map((m) => _MovieTile(
                          key: ValueKey(m.id),
                          movie: m,
                          onToggle: () {
                            HapticFeedback.mediumImpact();
                            ref.read(moviesProvider.notifier).toggle(m.id);
                          },
                          onDelete: () =>
                              ref.read(moviesProvider.notifier).delete(m.id),
                          onEdit: (t) => ref
                              .read(moviesProvider.notifier)
                              .updateTitle(m.id, t),
                        )),
                    if (watched.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _SectionDivider(label: 'WATCHED (${watched.length})'),
                      ...watched.map((m) => _MovieTile(
                            key: ValueKey(m.id),
                            movie: m,
                            onToggle: () {
                              HapticFeedback.lightImpact();
                              ref.read(moviesProvider.notifier).toggle(m.id);
                            },
                            onDelete: () =>
                                ref.read(moviesProvider.notifier).delete(m.id),
                            onEdit: (t) => ref
                                .read(moviesProvider.notifier)
                                .updateTitle(m.id, t),
                          )),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
        ),
        _AddBar(
          ctrl: _addCtrl,
          focusNode: _focusNode,
          isActive: _adding,
          bottomPad: bottomPad,
          hint: 'Add a movie to watch together…',
          onFocus: () => setState(() => _adding = true),
          onSubmit: _submit,
        ),
      ],
    );
  }
}

class _MovieTile extends StatefulWidget {
  const _MovieTile({
    super.key,
    required this.movie,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final MovieItem movie;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final ValueChanged<String> onEdit;

  @override
  State<_MovieTile> createState() => _MovieTileState();
}

class _MovieTileState extends State<_MovieTile> {
  bool _editing = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.movie.title);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _saveEdit() {
    if (_ctrl.text.trim().isNotEmpty) widget.onEdit(_ctrl.text.trim());
    setState(() => _editing = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final watched = widget.movie.isWatched;

    return Dismissible(
      key: ValueKey(widget.movie.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline,
            color: Colors.redAccent, size: 22),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: GestureDetector(
        onLongPress: () => setState(() => _editing = true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: watched
                ? Colors.white.withValues(alpha: 0.03)
                : const Color(0xFF111111),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: watched
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            children: [
              // Watched toggle
              GestureDetector(
                onTap: widget.onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: watched ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: watched
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: watched
                      ? const Icon(Icons.check, color: Colors.black, size: 14)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Movie icon
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: watched
                      ? Colors.white.withValues(alpha: 0.04)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.movie_outlined,
                  size: 16,
                  color: watched
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: _editing
                    ? TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: AppTextStyles.body,
                        cursorColor: AppColors.primary,
                        onEditingComplete: _saveEdit,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : Text(
                        widget.movie.title,
                        style: AppTextStyles.body.copyWith(
                          color: watched
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.9),
                          decoration: watched
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor:
                              Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ══════════════════════════════════════════════════════════════════════════════

class _AddBar extends StatelessWidget {
  const _AddBar({
    required this.ctrl,
    required this.focusNode,
    required this.isActive,
    required this.bottomPad,
    required this.onFocus,
    required this.onSubmit,
    this.hint = 'Add something to do together…',
  });

  final TextEditingController ctrl;
  final FocusNode focusNode;
  final bool isActive;
  final double bottomPad;
  final VoidCallback onFocus;
  final VoidCallback onSubmit;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomPad + safeBottom),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
            top:
                BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.07),
                ),
              ),
              child: TextField(
                controller: ctrl,
                focusNode: focusNode,
                style: AppTextStyles.body,
                cursorColor: AppColors.primary,
                textCapitalization: TextCapitalization.sentences,
                onTap: onFocus,
                onEditingComplete: onSubmit,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTextStyles.muted,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSubmit,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add, color: Colors.black, size: 22),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label,
              style: AppTextStyles.muted
                  .copyWith(fontSize: 10, letterSpacing: 1.4)),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
                color: Colors.white.withValues(alpha: 0.07), height: 1),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.message,
    this.onAdd,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 20),
            Text(message,
                style: AppTextStyles.body.copyWith(
                    color: AppColors.mutedForeground, height: 1.6),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
