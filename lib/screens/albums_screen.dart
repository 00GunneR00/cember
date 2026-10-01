import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/albums_controller.dart';
import '../core/api_client.dart';
import '../core/reveal_time.dart';
import '../core/token_store.dart';
import '../data/albums_repository.dart';
import '../data/http/http_albums_repository.dart';
import '../models/circle_summary.dart';
import '../models/joined_circle_summary.dart';
import '../models/photo_upload_mode.dart';
import '../theme/app_theme.dart';
import '../widgets/albums/archive_callout.dart';
import '../widgets/albums/live_circle_card.dart';
import '../widgets/albums/past_circle_card.dart';
import '../widgets/albums/quick_actions_row.dart';
import '../widgets/common/app_logo_mark.dart';
import '../widgets/common/live_dot.dart';
import '../widgets/common/pill_selector_row.dart';
import '../widgets/common/rules_editor.dart';
import '../widgets/common/section_header.dart';
import 'circle_detail_screen.dart';
import 'circle_list_screen.dart';
import 'qr_scan_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({
    super.key,
    this.repository = const MockAlbumsRepository(),
    this.apiClient,
    this.tokenStore = const TokenStore(),
  });

  final AlbumsRepository repository;
  final ApiClient? apiClient;
  final TokenStore tokenStore;

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  int _selectedFilter = 0;
  late final AlbumsRepository _effectiveRepository = widget.apiClient != null
      ? HttpAlbumsRepository(widget.apiClient!, tokenStore: widget.tokenStore)
      : widget.repository;
  late final AlbumsController controller = Get.put(
    AlbumsController(_effectiveRepository),
    tag: 'albums',
  );

  /// 0: everything · 1: archived circles only · 2: only circles the viewer owns (no guest circles).
  static const _filterLabels = [
    'Tüm Çemberlerim',
    'Kilitli Arşivler',
    'Yalnızca Ben',
  ];

  Future<void> _openCircleDetail(String circleId) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CircleDetailScreen(circleId: circleId, apiClient: widget.apiClient),
      ),
    );
    // Whatever changed in there — a new cover, new photos, a deletion — shows up without pull-to-refresh.
    controller.load(silent: true);
    if (deleted == true) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Çember silindi.')));
      }
    }
  }

  Future<void> _openJoinedCircleDetail(JoinedCircleSummary joined) async {
    if (widget.apiClient == null) return;
    final guestClient = ApiClient(
      baseUrl: widget.apiClient!.dio.options.baseUrl,
      bearerToken: joined.guestToken,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CircleDetailScreen(
          circleId: joined.circle.id,
          apiClient: guestClient,
        ),
      ),
    );
    controller.load(silent: true);
  }

  List<CircleListEntry> _ownEntries(Iterable<CircleSummary> circles) => [
    for (final c in circles)
      CircleListEntry(circle: c, onOpen: () => _openCircleDetail(c.id)),
  ];

  List<CircleListEntry> _joinedEntries(Iterable<JoinedCircleSummary> joined) =>
      [
        for (final j in joined)
          CircleListEntry(
            circle: j.circle,
            onOpen: () => _openJoinedCircleDetail(j),
          ),
      ];

  /// Pushes a circle list that rebuilds from [controller], so a circle deleted from inside it disappears.
  void _pushCircleList({
    required String title,
    required String emptyMessage,
    required List<CircleListEntry> Function() entries,
    bool grid = false,
    bool searchable = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Obx(
          () => CircleListScreen(
            title: title,
            entries: entries(),
            emptyMessage: emptyMessage,
            grid: grid,
            searchable: searchable,
          ),
        ),
      ),
    );
  }

  void _openAllLiveCircles() => _pushCircleList(
    title: 'Canlı Çemberler',
    emptyMessage: 'Şu an canlı bir çemberin yok.',
    entries: () => [
      ..._ownEntries(controller.overview.value?.live ?? const []),
      ..._joinedEntries(
        controller.joinedCircles.where((j) => !j.circle.isArchived),
      ),
    ],
  );

  void _openArchive() => _pushCircleList(
    title: 'Tüm Arşiv',
    emptyMessage: 'Henüz arşivlenmiş bir çemberin yok.',
    grid: true,
    entries: () => [
      ..._ownEntries(controller.overview.value?.past ?? const []),
      ..._joinedEntries(
        controller.joinedCircles.where((j) => j.circle.isArchived),
      ),
    ],
  );

  void _openSearch() => _pushCircleList(
    title: 'Ara',
    emptyMessage: 'Henüz bir çemberin yok.',
    searchable: true,
    entries: () => [
      ..._ownEntries(controller.overview.value?.live ?? const []),
      ..._joinedEntries(controller.joinedCircles),
      ..._ownEntries(controller.overview.value?.past ?? const []),
    ],
  );

  Future<void> _joinWithQr() async {
    if (widget.apiClient == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QrScanScreen(
          apiClient: widget.apiClient!,
          tokenStore: widget.tokenStore,
          defaultDisplayName: controller.overview.value?.userName ?? '',
        ),
      ),
    );
    controller.load(silent: true);
  }

  Future<void> _createCircle() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    var visibilityIndex = 0;
    const uploadModes = [
      PhotoUploadMode.quickCaptureOnly,
      PhotoUploadMode.galleryOnly,
      PhotoUploadMode.both,
    ];
    var uploadModeIndex = 2;
    // Non-null when Banyo modu is on.
    DateTime? revealAt;
    // Updated by the rules editor as the host types; empty means no rules.
    var rules = <String>[];

    final result = await showDialog<_NewCircleResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final colors = context.colors;
          final dateLabel = selectedDate == null
              ? 'Tarih seç'
              : '${selectedDate!.day.toString().padLeft(2, '0')}.${selectedDate!.month.toString().padLeft(2, '0')}.${selectedDate!.year}';
          return AlertDialog(
            title: const Text('Yeni Çember'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Etkinlik adı'),
                    // Re-render so "Oluştur" enables as soon as there's a name.
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: descriptionController,
                    maxLength: 160,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Motto / kısa açıklama (opsiyonel)',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 3),
                        ),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            dateLabel,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      for (final (i, label) in const [
                        'Herkese Açık',
                        'Kilitli',
                      ].indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setDialogState(() => visibilityIndex = i),
                            child: Container(
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: visibilityIndex == i
                                    ? colors.primary
                                    : colors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                label,
                                style: AppTextStyles.labelMd.copyWith(
                                  color: visibilityIndex == i
                                      ? colors.onPrimary
                                      : colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Fotoğraf yükleme yöntemi',
                    style: AppTextStyles.labelSm.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final (i, label) in const [
                        'Şipşak',
                        'Galeriden',
                        'Her ikisi',
                      ].indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setDialogState(() => uploadModeIndex = i),
                            child: Container(
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: uploadModeIndex == i
                                    ? colors.primary
                                    : colors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                label,
                                style: AppTextStyles.labelMd.copyWith(
                                  color: uploadModeIndex == i
                                      ? colors.onPrimary
                                      : colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: revealAt != null,
                    onChanged: (on) => setDialogState(
                      () => revealAt = on
                          ? defaultRevealTime(selectedDate)
                          : null,
                    ),
                    activeThumbColor: Colors.white,
                    activeTrackColor: colors.secondary,
                    title: Text(
                      'Banyo Modu 🎞️',
                      style: AppTextStyles.labelLg.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    subtitle: Text(
                      'Fotoğraflar açılış anına kadar gizli kalır, sonra herkese birlikte açılır.',
                      style: AppTextStyles.bodySm.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (revealAt != null)
                    InkWell(
                      onTap: () async {
                        final picked = await pickRevealTime(context, revealAt!);
                        if (picked != null) {
                          setDialogState(() => revealAt = picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 18,
                              color: colors.secondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Açılış: ${formatRevealTime(revealAt!)}',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Değiştir',
                              style: AppTextStyles.labelMd.copyWith(
                                color: colors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Kurallar (opsiyonel)',
                    style: AppTextStyles.labelSm.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RulesEditor(onChanged: (updated) => rules = updated),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: nameController.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(context).pop(
                        _NewCircleResult(
                          nameController.text.trim(),
                          selectedDate,
                          visibilityIndex == 0,
                          descriptionController.text.trim(),
                          uploadModes[uploadModeIndex],
                          revealAt,
                          rules,
                        ),
                      ),
                child: const Text('Oluştur'),
              ),
            ],
          );
        },
      ),
    );
    if (result == null || result.name.isEmpty) return;
    final created = await controller.createCircle(
      result.name,
      eventDate: result.eventDate,
      isOpenJoin: result.isOpenJoin,
      description: result.description.isEmpty ? null : result.description,
      uploadMode: result.uploadMode,
      // A reveal time picked long ago in the open dialog may have slipped into the past.
      revealAt: result.revealAt?.isAfter(DateTime.now()) == true
          ? result.revealAt
          : null,
      rules: result.rules,
    );
    if (!mounted) return;
    final id = created.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(created.error ?? 'Çember oluşturulamadı, tekrar dene.'),
        ),
      );
      return;
    }
    _openCircleDetail(id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error.value != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.error.value!,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: controller.load,
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }
          final overview = controller.overview.value;
          final liveCircles = overview?.live ?? const [];
          final pastCircles = overview?.past ?? const [];
          final userName = overview?.userName ?? '';
          final joinedCircles = controller.joinedCircles;

          return RefreshIndicator(
            onRefresh: controller.load,
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
                SliverToBoxAdapter(
                  child: _Greeting(
                    userName: userName,
                    activeCount: liveCircles.length,
                    onSearch: _openSearch,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile,
                      vertical: AppSpacing.xs,
                    ),
                    child: QuickActionsRow(
                      onJoinWithQr: _joinWithQr,
                      onCreateCircle: _createCircle,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile,
                      vertical: AppSpacing.xs,
                    ),
                    child: PillSelectorRow(
                      labels: _filterLabels,
                      selectedIndex: _selectedFilter,
                      onSelected: (i) => setState(() => _selectedFilter = i),
                      textStyle: AppTextStyles.labelSm,
                      horizontalPadding: 0,
                    ),
                  ),
                ),
                if (_selectedFilter != 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        bottom: AppSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.marginMobile,
                            ),
                            child: SectionHeader(
                              title: 'Canlı Çemberler',
                              countPillLabel: '${liveCircles.length} Anlık',
                              trailingActionLabel: 'Tümü',
                              onTrailingAction: _openAllLiveCircles,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.marginMobile,
                            ),
                            child: Column(
                              children: liveCircles
                                  .map(
                                    (c) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md,
                                      ),
                                      child: LiveCircleCard(
                                        circle: c,
                                        onTap: () => _openCircleDetail(c.id),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_selectedFilter == 0 && joinedCircles.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.marginMobile,
                            ),
                            child: SectionHeader(
                              title: 'Katıldığım Çemberler',
                              countPillLabel: '${joinedCircles.length} Misafir',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.marginMobile,
                            ),
                            child: Column(
                              children: joinedCircles
                                  .map(
                                    (j) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md,
                                      ),
                                      child: LiveCircleCard(
                                        circle: j.circle,
                                        onTap: () => _openJoinedCircleDetail(j),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      AppSpacing.md,
                      AppSpacing.marginMobile,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Geçmiş Çemberler',
                          icon: Icons.lock_clock,
                          trailingText: '${pastCircles.length} Arşiv',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: AppSpacing.gutterMobile,
                          mainAxisSpacing: AppSpacing.gutterMobile,
                          childAspectRatio: 0.78,
                          children: [
                            ...pastCircles.map(
                              (c) => PastCircleCard(
                                circle: c,
                                onTap: () => _openCircleDetail(c.id),
                              ),
                            ),
                            ArchiveCallout(onTap: _openArchive),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _NewCircleResult {
  const _NewCircleResult(
    this.name,
    this.eventDate,
    this.isOpenJoin,
    this.description,
    this.uploadMode,
    this.revealAt,
    this.rules,
  );

  final String name;
  final DateTime? eventDate;
  final bool isOpenJoin;
  final String description;
  final PhotoUploadMode uploadMode;
  final DateTime? revealAt;
  final List<String> rules;
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.marginMobile,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          const AppLogoMark(size: 32),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Çember',
            style: AppTextStyles.headlineSm.copyWith(color: colors.primary),
          ),
          const Spacer(),
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.surfaceContainerHigh,
            child: Icon(Icons.person, size: 18, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.userName,
    required this.activeCount,
    required this.onSearch,
  });

  final String userName;
  final int activeCount;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.marginMobile,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Merhaba $userName',
                      style: AppTextStyles.headlineLgMobile.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const LiveDot(),
                    const SizedBox(width: 8),
                    Text(
                      '$activeCount aktif çemberdesin',
                      style: AppTextStyles.bodySm.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Çemberlerinde ara',
            child: GestureDetector(
              onTap: onSearch,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(Icons.search, color: colors.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
