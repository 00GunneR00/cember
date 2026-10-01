import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/discover_controller.dart';
import '../core/api_client.dart';
import '../core/token_store.dart';
import '../data/challenge_repository.dart';
import '../data/discover_repository.dart';
import '../data/http/http_discover_repository.dart';
import '../models/challenge_template.dart';
import '../models/public_circle_summary.dart';
import '../theme/app_theme.dart';
import '../widgets/common/pill_selector_row.dart';
import '../widgets/discover/brand_circle_card.dart';
import '../widgets/discover/challenge_card.dart';
import 'challenge_detail_screen.dart';
import 'discover_preview_screen.dart';

/// Keşfet, in two parts: Markalar — brands' own circles with their mottos — and Challenge — ready-made
/// circle ideas to start with friends.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    this.repository = const MockDiscoverRepository(),
    this.challengeRepository,
    this.apiClient,
    this.tokenStore = const TokenStore(),
  });

  final DiscoverRepository repository;
  final ChallengeRepository? challengeRepository;
  final ApiClient? apiClient;
  final TokenStore tokenStore;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  static const _brandsTab = 0;
  static const _challengesTab = 1;

  late final DiscoverRepository _effectiveRepository = widget.apiClient != null ? HttpDiscoverRepository(widget.apiClient!) : widget.repository;
  late final DiscoverController controller = Get.put(DiscoverController(_effectiveRepository), tag: 'discover');
  late final ChallengeRepository? _challengeRepository =
      widget.challengeRepository ?? (widget.apiClient != null ? HttpChallengeRepository(widget.apiClient!) : null);

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  int _tab = _brandsTab;
  late Future<List<ChallengeTemplate>> _challenges = _loadChallenges();
  ChallengeCategory? _category;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    Get.delete<DiscoverController>(tag: 'discover');
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<List<ChallengeTemplate>> _loadChallenges() => _challengeRepository?.fetchAll() ?? Future.value(const []);

  Future<void> _refreshChallenges() async {
    final next = _loadChallenges();
    setState(() {
      _challenges = next;
    });
    await next;
  }

  void _onScroll() {
    if (_tab == _brandsTab && _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      controller.loadMore();
    }
  }

  void _onSearchChanged(String value) {
    if (_tab == _challengesTab) {
      setState(() {}); // challenges filter locally as you type
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => controller.load(query: value.trim()));
  }

  void _switchTab(int tab) {
    if (tab == _tab) return;
    final hadQuery = _searchController.text.trim().isNotEmpty;
    _searchController.clear();
    // Leaving Markalar with a search typed in: bring back the full list for next time.
    if (_tab == _brandsTab && hadQuery) controller.load(query: '');
    setState(() => _tab = tab);
  }

  void _openBrandCircle(PublicCircleSummary circle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiscoverCirclePreviewScreen(circle: circle, controller: controller, apiClient: widget.apiClient, tokenStore: widget.tokenStore),
      ),
    );
  }

  Future<void> _openChallenge(ChallengeTemplate challenge) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChallengeDetailScreen(challenge: challenge, apiClient: widget.apiClient),
      ),
    );
    // "N grup başlattı" may have just gone up.
    if (mounted) unawaited(_refreshChallenges());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.xs, AppSpacing.marginMobile, AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Keşfet', style: AppTextStyles.headlineLgMobile.copyWith(color: colors.primary)),
                  const SizedBox(height: 2),
                  Text(
                    _tab == _brandsTab ? 'Markaların mottolarıyla açtığı çemberlere katıl.' : 'Bir fikir seç, kendi çemberini başlat, arkadaşlarını davet et.',
                    style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PillSelectorRow(labels: const ['Markalar', 'Challenge'], selectedIndex: _tab, onSelected: _switchTab, horizontalPadding: 0),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: _tab == _brandsTab ? 'Marka çemberi ara...' : 'Challenge ara...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: colors.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.pill), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _tab == _brandsTab ? _buildBrands(colors) : _buildChallenges(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildBrands(AppColorTokens colors) {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error.value != null) {
        return _Message(
          icon: Icons.cloud_off,
          text: controller.error.value!,
          action: TextButton(onPressed: () => controller.load(), child: const Text('Tekrar Dene')),
        );
      }
      if (controller.circles.isEmpty) {
        return _Message(
          icon: Icons.storefront_outlined,
          text: _searchController.text.trim().isEmpty
              ? 'Şu an aktif bir marka çemberi yok. Bu arada arkadaşlarınla bir challenge başlatabilirsin.'
              : 'Aramana uyan bir marka çemberi yok.',
          action: TextButton(onPressed: () => _switchTab(_challengesTab), child: const Text('Challenge\'lara göz at ›')),
        );
      }
      return RefreshIndicator(
        onRefresh: () => controller.load(),
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.xs, AppSpacing.marginMobile, 100),
          itemCount: controller.circles.length + (controller.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index >= controller.circles.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final circle = controller.circles[index];
            return BrandCircleCard(circle: circle, onTap: () => _openBrandCircle(circle));
          },
        ),
      );
    });
  }

  Widget _buildChallenges(AppColorTokens colors) {
    return FutureBuilder<List<ChallengeTemplate>>(
      future: _challenges,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _Message(
            icon: Icons.cloud_off,
            text: 'Challenge\'lar yüklenemedi.',
            action: TextButton(onPressed: _refreshChallenges, child: const Text('Tekrar Dene')),
          );
        }
        final all = snapshot.data!;
        final query = _searchController.text.trim().toLowerCase();
        final visible = all.where((c) {
          if (_category != null && c.category != _category) return false;
          if (query.isEmpty) return true;
          return c.title.toLowerCase().contains(query) || c.tagline.toLowerCase().contains(query);
        }).toList();
        final categories = ChallengeCategory.values.where((cat) => all.any((c) => c.category == cat)).toList();

        return Column(
          children: [
            PillSelectorRow(
              labels: ['Tümü', ...categories.map((c) => c.label)],
              selectedIndex: _category == null ? 0 : categories.indexOf(_category!) + 1,
              onSelected: (i) => setState(() => _category = i == 0 ? null : categories[i - 1]),
              textStyle: AppTextStyles.labelSm,
              height: 32,
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshChallenges,
                child: visible.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          _Message(icon: Icons.search_off, text: 'Bu aramaya uyan bir challenge yok.'),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.marginMobile, AppSpacing.xs, AppSpacing.marginMobile, 100),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) => ChallengeCard(challenge: visible[i], onTap: () => _openChallenge(visible[i])),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.sm),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: colors.onSurfaceVariant),
            ),
            if (action != null) ...[const SizedBox(height: AppSpacing.xs), action!],
          ],
        ),
      ),
    );
  }
}
