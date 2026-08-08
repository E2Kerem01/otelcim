import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/constants/categories.dart';
import '../../../shared/constants/listing_filters.dart';
import '../../../shared/providers/paginated_listings_provider.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/listing_service.dart';
import '../../../shared/utils/match_score.dart';
import '../../../shared/services/notification_service.dart';
import '../../ads/presentation/widgets/banner_ad_carousel.dart';
import '../../boosts/presentation/widgets/boost_badge.dart';
import '../../favorites/services/favorite_service.dart';
import '../../listings/domain/listing_model.dart';
import '../../listings/presentation/season_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../discovery/domain/tourism_region.dart';
import '../../../core/responsive/responsive_layout.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.initialRegion});

  final String? initialRegion;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  bool _hasSearchText = false;
  int _columnCount = 1;
  bool _columnCountInitialized = false;
  _AdvancedFilters _filters = const _AdvancedFilters();
  PaginationParams _currentParams = (
    category: null,
    searchQuery: '',
    city: null,
    region: null,
    minSalaryTl: null,
    maxSalaryTl: null,
    dateFilter: ListingDateFilter.all,
    employmentType: null,
    sortOrder: ListingSortOrder.newest,
    season: null,
  );

  @override
  void initState() {
    super.initState();
    _filters = _AdvancedFilters(region: widget.initialRegion);
    _scrollController.addListener(_onScroll);
    final initialRegion = widget.initialRegion;
    if (initialRegion != null) {
      Future.microtask(
        () => ref.read(notificationServiceProvider).selectRegion(initialRegion),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_columnCountInitialized) {
      _columnCountInitialized = true;
      final width = MediaQuery.sizeOf(context).width;
      if (width >= desktopBreakpoint) {
        _columnCount = 4;
      } else if (width >= tabletBreakpoint) {
        _columnCount = 3;
      } else if (width >= mobileBreakpoint) {
        _columnCount = 2;
      }
    }
    if (context.isMobile && _columnCount > 2) {
      _columnCount = 2;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final hasSearchText = value.isNotEmpty;
    if (_hasSearchText != hasSearchText) {
      setState(() => _hasSearchText = hasSearchText);
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim());
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _hasSearchText = false;
      _searchQuery = '';
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(paginatedListingsProvider(_currentParams).notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref
        .read(paginatedListingsProvider(_currentParams).notifier)
        .refresh();

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_AdvancedFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FilterSheet(
        initial: _filters,
        listingService: ref.read(listingServiceProvider),
      ),
    );
    if (result != null && mounted) {
      setState(() => _filters = result);
      if (result.region != null) {
        await ref
            .read(notificationServiceProvider)
            .selectRegion(result.region!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final availableColumnCounts = context.isMobile
        ? const [1, 2]
        : const [1, 2, 3, 4];
    _currentParams = (
      category: selectedCategory?.name,
      searchQuery: _searchQuery,
      city: _filters.city,
      region: _filters.region,
      minSalaryTl: _filters.minSalaryTl,
      maxSalaryTl: _filters.maxSalaryTl,
      dateFilter: _filters.dateFilter,
      employmentType: _filters.employmentType,
      sortOrder: _filters.sortOrder,
      season: _filters.season?.code,
    );
    final paginationState = ref.watch(
      paginatedListingsProvider(_currentParams),
    );

    if (paginationState.listings.isEmpty &&
        !paginationState.isLoading &&
        paginationState.hasMore) {
      final notifier = ref.read(
        paginatedListingsProvider(_currentParams).notifier,
      );
      Future.microtask(notifier.loadInitial);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialRegion == null
              ? 'Otelcim'
              : (Localizations.localeOf(context).languageCode == 'en'
                        ? tourismRegionById(widget.initialRegion)?.nameEn
                        : tourismRegionById(widget.initialRegion)?.nameTr) ??
                    AppLocalizations.of(context)!.regionsTitle,
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/seasonal-calendar'),
            tooltip: 'Sezon Takvimi',
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          IconButton(
            onPressed: () => context.push('/regions'),
            tooltip: AppLocalizations.of(context)!.regionsTitle,
            icon: const Icon(Icons.travel_explore),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'İş ilanı ara...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Colors.grey,
                            ),
                            suffixIcon: _hasSearchText
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 20,
                                    ),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Badge(
                      isLabelVisible: _filters.activeCount > 0,
                      label: Text('${_filters.activeCount}'),
                      child: IconButton.filledTonal(
                        onPressed: _openFilters,
                        tooltip: 'Filtreler',
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: FilledButton.tonalIcon(
                  onPressed: () => context.push('/nearby'),
                  icon: const Icon(Icons.near_me_outlined),
                  label: Text(AppLocalizations.of(context)!.nearMe),
                ),
              ),
            ),
            if (_filters.activeCount > 0)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_filters.city != null)
                        _filterChip(
                          _filters.city!,
                          () => setState(
                            () => _filters = _filters.copyWith(clearCity: true),
                          ),
                        ),
                      if (_filters.region != null)
                        _filterChip(
                          (Localizations.localeOf(context).languageCode == 'en'
                                  ? tourismRegionById(_filters.region)?.nameEn
                                  : tourismRegionById(
                                      _filters.region,
                                    )?.nameTr) ??
                              _filters.region!,
                          () => setState(
                            () =>
                                _filters = _filters.copyWith(clearRegion: true),
                          ),
                        ),
                      if (_filters.minSalaryTl != null ||
                          _filters.maxSalaryTl != null)
                        _filterChip(
                          _filters.salaryLabel,
                          () => setState(
                            () =>
                                _filters = _filters.copyWith(clearSalary: true),
                          ),
                        ),
                      if (_filters.dateFilter != ListingDateFilter.all)
                        _filterChip(
                          _filters.dateFilter.label,
                          () => setState(
                            () => _filters = _filters.copyWith(
                              dateFilter: ListingDateFilter.all,
                            ),
                          ),
                        ),
                      if (_filters.employmentType != null)
                        _filterChip(
                          _filters.employmentType!.label,
                          () => setState(
                            () => _filters = _filters.copyWith(
                              clearEmploymentType: true,
                            ),
                          ),
                        ),
                      if (_filters.season != null)
                        _filterChip(
                          _filters.season!.label,
                          () => setState(
                            () =>
                                _filters = _filters.copyWith(clearSeason: true),
                          ),
                        ),
                      if (_filters.sortOrder != ListingSortOrder.newest)
                        _filterChip(
                          _filters.sortOrder.label,
                          () => setState(
                            () => _filters = _filters.copyWith(
                              sortOrder: ListingSortOrder.newest,
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _filters = const _AdvancedFilters()),
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: BannerAdCarousel(),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: ListingCategory.values.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = selectedCategory == null;
                      return ChoiceChip(
                        label: const Text('Tümü'),
                        selected: isSelected,
                        onSelected: (_) =>
                            ref
                                    .read(
                                      selectedCategoryFilterProvider.notifier,
                                    )
                                    .state =
                                null,
                        selectedColor: Theme.of(context).primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      );
                    }
                    final category = ListingCategory.values[index - 1];
                    final isSelected = category == selectedCategory;
                    return ChoiceChip(
                      label: Text(listingCategoryLabels[category]!),
                      selected: isSelected,
                      onSelected: (_) =>
                          ref
                                  .read(selectedCategoryFilterProvider.notifier)
                                  .state =
                              category,
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    Text(
                      '${paginationState.listings.length} sonuç',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: availableColumnCounts.map((cols) {
                          final isSelected = _columnCount == cols;
                          return Tooltip(
                            message: '$cols Sütun',
                            child: InkWell(
                              key: Key('grid_col_$cols'),
                              onTap: () => setState(() => _columnCount = cols),
                              borderRadius: BorderRadius.circular(6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      cols == 1
                                          ? Icons.view_list_rounded
                                          : cols == 2
                                              ? Icons.grid_view_rounded
                                              : cols == 3
                                                  ? Icons.grid_on_rounded
                                                  : Icons.apps_rounded,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$cols',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (paginationState.isLoading && paginationState.listings.isEmpty)
              _ListingsSkeletonSliver(columnCount: _columnCount)
            else if (paginationState.listings.isEmpty)
              _buildEmptyState(context)
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: _columnCount == 1
                    ? SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ListingCard(
                              listing: paginationState.listings[index],
                              columnCount: 1,
                            ),
                          ),
                          childCount: paginationState.listings.length,
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _columnCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: _columnCount == 2
                              ? 0.80
                              : _columnCount == 3
                                  ? 0.88
                                  : 1.05,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _ListingCard(
                            listing: paginationState.listings[index],
                            columnCount: _columnCount,
                          ),
                          childCount: paginationState.listings.length,
                        ),
                      ),
              ),
              if (paginationState.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hotel_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Henüz İlan Bulunmuyor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sistemde aktif ilan bulunmamaktadır. Örnek ilanları veritabanına ekleyebilir veya yeni bir ilan oluşturabilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(listingServiceProvider).seedSampleListings();
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Örnek İlanları Veritabanına Yükle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/create-listing'),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('İlk İlanı Sen Oluştur'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onDeleted) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: InputChip(label: Text(label), onDeleted: onDeleted),
  );
}

class _AdvancedFilters {
  const _AdvancedFilters({
    this.city,
    this.region,
    this.minSalaryTl,
    this.maxSalaryTl,
    this.dateFilter = ListingDateFilter.all,
    this.employmentType,
    this.sortOrder = ListingSortOrder.newest,
    this.season,
  });

  final String? city;
  final String? region;
  final int? minSalaryTl;
  final int? maxSalaryTl;
  final ListingDateFilter dateFilter;
  final EmploymentType? employmentType;
  final ListingSortOrder sortOrder;
  final ListingSeason? season;

  int get activeCount => [
    city != null,
    region != null,
    minSalaryTl != null || maxSalaryTl != null,
    dateFilter != ListingDateFilter.all,
    employmentType != null,
    sortOrder != ListingSortOrder.newest,
    season != null,
  ].where((active) => active).length;

  String get salaryLabel {
    if (minSalaryTl != null && maxSalaryTl != null)
      return '$minSalaryTl - $maxSalaryTl TL';
    if (minSalaryTl != null) return '$minSalaryTl TL ve üzeri';
    return '$maxSalaryTl TL ve altı';
  }

  _AdvancedFilters copyWith({
    String? city,
    String? region,
    int? minSalaryTl,
    int? maxSalaryTl,
    ListingDateFilter? dateFilter,
    EmploymentType? employmentType,
    ListingSortOrder? sortOrder,
    ListingSeason? season,
    bool clearCity = false,
    bool clearRegion = false,
    bool clearSalary = false,
    bool clearEmploymentType = false,
    bool clearSeason = false,
  }) => _AdvancedFilters(
    city: clearCity ? null : city ?? this.city,
    region: clearRegion ? null : region ?? this.region,
    minSalaryTl: clearSalary ? null : minSalaryTl ?? this.minSalaryTl,
    maxSalaryTl: clearSalary ? null : maxSalaryTl ?? this.maxSalaryTl,
    dateFilter: dateFilter ?? this.dateFilter,
    employmentType: clearEmploymentType
        ? null
        : employmentType ?? this.employmentType,
    sortOrder: sortOrder ?? this.sortOrder,
    season: clearSeason ? null : season ?? this.season,
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial, required this.listingService});
  final _AdvancedFilters initial;
  final ListingService listingService;
  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  String? _city;
  String? _region;
  ListingCategory? _category;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late ListingDateFilter _date;
  EmploymentType? _employmentType;
  late ListingSortOrder _sort;
  ListingSeason? _season;
  Map<String, int> _regionCounts = const {};
  Map<String, int> _seasonCounts = const {};

  @override
  void initState() {
    super.initState();
    _city = widget.initial.city;
    _region = widget.initial.region;
    _category = ref.read(selectedCategoryFilterProvider);
    _minController = TextEditingController(
      text: widget.initial.minSalaryTl?.toString() ?? '',
    );
    _maxController = TextEditingController(
      text: widget.initial.maxSalaryTl?.toString() ?? '',
    );
    _date = widget.initial.dateFilter;
    _employmentType = widget.initial.employmentType;
    _sort = widget.initial.sortOrder;
    _season = widget.initial.season;
    _loadLiveCounts();
  }

  Future<void> _loadLiveCounts() async {
    try {
      final results = await Future.wait([
        ...tourismRegions.map(
          (region) => widget.listingService
              .countActiveListings(region: region.id)
              .then((count) => (key: region.id, count: count, isRegion: true)),
        ),
        ...ListingSeason.values.map(
          (season) => widget.listingService
              .countActiveListings(season: season.code)
              .then(
                (count) => (key: season.code, count: count, isRegion: false),
              ),
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _regionCounts = {
          for (final result in results)
            if (result.isRegion) result.key: result.count,
        };
        _seasonCounts = {
          for (final result in results)
            if (!result.isRegion) result.key: result.count,
        };
      });
    } catch (_) {
      // Keep labels usable without counts when an aggregate request fails.
    }
  }

  String _withCount(String label, int? count) {
    return count == null ? label : '$label ($count)';
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Gelişmiş filtreler',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _city,
            decoration: const InputDecoration(labelText: 'Şehir / bölge'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Tüm şehirler'),
              ),
              ...turkishTourismCities.map(
                (city) => DropdownMenuItem(value: city, child: Text(city)),
              ),
            ],
            onChanged: (value) => setState(() => _city = value),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<ListingCategory?>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'İş branşı'),
            items: [
              const DropdownMenuItem<ListingCategory?>(
                value: null,
                child: Text('Tüm branşlar'),
              ),
              ...ListingCategory.values.map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(listingCategoryLabels[value]!),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _category = value),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String?>(
            initialValue: _region,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.regionLabel,
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(AppLocalizations.of(context)!.regionsTitle),
              ),
              ...tourismRegions.map(
                (region) => DropdownMenuItem(
                  value: region.id,
                  child: Text(
                    _withCount(
                      Localizations.localeOf(context).languageCode == 'en'
                          ? region.nameEn
                          : region.nameTr,
                      _regionCounts[region.id],
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _region = value),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'En düşük maaş'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'En yüksek maaş',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<ListingDateFilter>(
            initialValue: _date,
            decoration: const InputDecoration(labelText: 'İlan tarihi'),
            items: ListingDateFilter.values
                .map(
                  (value) =>
                      DropdownMenuItem(value: value, child: Text(value.label)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _date = value);
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<EmploymentType?>(
            initialValue: _employmentType,
            decoration: const InputDecoration(labelText: 'Çalışma tipi'),
            items: [
              const DropdownMenuItem<EmploymentType?>(
                value: null,
                child: Text('Tüm çalışma tipleri'),
              ),
              ...EmploymentType.values.map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.label)),
              ),
            ],
            onChanged: (value) => setState(() => _employmentType = value),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<ListingSeason?>(
            initialValue: _season,
            decoration: const InputDecoration(labelText: 'Sezon'),
            items: [
              const DropdownMenuItem<ListingSeason?>(
                value: null,
                child: Text('Farketmez / Tüm Sezonlar'),
              ),
              ...ListingSeason.values.map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(_withCount(s.label, _seasonCounts[s.code])),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _season = value),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<ListingSortOrder>(
            initialValue: _sort,
            decoration: const InputDecoration(labelText: 'Sıralama'),
            items: ListingSortOrder.values
                .map(
                  (value) =>
                      DropdownMenuItem(value: value, child: Text(value.label)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _sort = value);
            },
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(selectedCategoryFilterProvider.notifier).state =
                        null;
                    Navigator.pop(context, const _AdvancedFilters());
                  },
                  child: const Text('Temizle'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final min = int.tryParse(_minController.text.trim());
                    final max = int.tryParse(_maxController.text.trim());
                    if (min != null && max != null && min > max) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Maaş aralığını kontrol edin.'),
                        ),
                      );
                      return;
                    }
                    ref.read(selectedCategoryFilterProvider.notifier).state =
                        _category;
                    Navigator.pop(
                      context,
                      _AdvancedFilters(
                        city: _city,
                        region: _region,
                        minSalaryTl: min,
                        maxSalaryTl: max,
                        dateFilter: _date,
                        employmentType: _employmentType,
                        sortOrder: _sort,
                        season: _season,
                      ),
                    );
                  },
                  child: const Text('Filtreleri uygula'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Skeleton placeholder cards shown while the initial page of listings loads.
class _ListingsSkeletonSliver extends StatelessWidget {
  const _ListingsSkeletonSliver({this.columnCount = 1});

  final int columnCount;

  @override
  Widget build(BuildContext context) {
    if (columnCount == 1) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SkeletonCard(columnCount: 1),
            ),
            childCount: 4,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columnCount == 2
              ? 0.80
              : columnCount == 3
                  ? 0.88
                  : 1.05,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _SkeletonCard(columnCount: columnCount),
          childCount: columnCount * 2,
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({this.columnCount = 1});
  final int columnCount;

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGrid = widget.columnCount > 1;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.4 + (_controller.value * 0.3);
        return Opacity(opacity: opacity, child: child);
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: isGrid
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(color: Colors.grey.shade300),
                  ),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            width: 60,
                            height: 12,
                            color: Colors.grey.shade300,
                          ),
                          Container(
                            width: double.infinity,
                            height: 12,
                            color: Colors.grey.shade300,
                          ),
                          Container(
                            width: 80,
                            height: 10,
                            color: Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 16,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 160,
                      height: 12,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 14,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ListingCard extends ConsumerWidget {
  const _ListingCard({required this.listing, this.columnCount = 1});

  final Listing listing;
  final int columnCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBoostedActive = BoostBadge.isBoostActive(listing);
    final uid = ref.watch(authStateProvider).value?.uid;
    final isFavorite = uid == null
        ? false
        : ref
                  .watch(favoriteIdsProvider(uid))
                  .valueOrNull
                  ?.contains(listing.id) ??
              false;
    final profile = uid == null
        ? null
        : ref.watch(currentUserProfileProvider).valueOrNull;
    final matchScore = profile?.userType == 'jobseeker'
        ? calculateMatchScore(listing: listing, profile: profile!)
        : null;

    final isGrid = columnCount > 1;

    if (isGrid) {
      return Card(
        clipBehavior: Clip.antiAlias,
        elevation: isBoostedActive ? 3 : 1,
        shape: isBoostedActive
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.amber.shade400, width: 1.5),
              )
            : null,
        child: InkWell(
          onTap: () => context.push('/listing/${listing.id}'),
          child: Container(
            decoration: isBoostedActive
                ? BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade50.withValues(alpha: 0.35),
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: listing.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: listing.images.first,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.grey.shade200,
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade100,
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 24,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    listingCategoryColor(listing.category),
                                    listingCategoryColor(
                                      listing.category,
                                    ).withValues(alpha: 0.72),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  listingCategoryIcon(listing.category),
                                  size: 34,
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white.withValues(alpha: 0.85),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 16,
                          tooltip: isFavorite
                              ? 'Favorilerden çıkar'
                              : 'Favorilere ekle',
                          onPressed: () {
                            if (uid == null) {
                              context.push('/login');
                              return;
                            }
                            ref
                                .read(favoriteServiceProvider)
                                .toggleFavorite(uid, listing.id);
                          },
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? Colors.red
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    if (isBoostedActive)
                      const Positioned(
                        top: 4,
                        left: 4,
                        child: BoostBadge(isCompact: true),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: listingCategoryColor(
                                        listing.category,
                                      ).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      listingCategoryLabel(listing.category),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: listingCategoryColor(
                                          listing.category,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (listing.isUrgent) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.shade700,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.urgentBadge,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              listing.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: columnCount >= 3 ? 12 : 13,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    listing.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              listing.salary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: columnCount >= 3 ? 12 : 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isBoostedActive ? 3 : 1,
      shape: isBoostedActive
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.amber.shade400, width: 1.5),
            )
          : null,
      child: InkWell(
        onTap: () => context.push('/listing/${listing.id}'),
        child: Container(
          decoration: isBoostedActive
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade50.withValues(alpha: 0.35),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: listingCategoryColor(
                          listing.category,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listingCategoryLabel(listing.category),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: listingCategoryColor(listing.category),
                        ),
                      ),
                    ),
                    if (isBoostedActive) ...[
                      const SizedBox(width: 8),
                      const BoostBadge(isCompact: true),
                    ],
                    if (isSeasonalContract(listing.season)) ...[
                      const SizedBox(width: 8),
                      SeasonBadge(season: listing.season!),
                    ],
                    if (matchScore != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade300),
                        ),
                        child: Text(
                          '%$matchScore ${AppLocalizations.of(context)!.matchLabel}',
                          style: TextStyle(
                            color: Colors.teal.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    if (listing.isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.urgentBadge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    AnimatedScale(
                      scale: isFavorite ? 1.15 : 1,
                      duration: const Duration(milliseconds: 180),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: isFavorite
                            ? 'Favorilerden çıkar'
                            : 'Favorilere ekle',
                        onPressed: () {
                          if (uid == null) {
                            context.push('/login');
                            return;
                          }
                          ref
                              .read(favoriteServiceProvider)
                              .toggleFavorite(uid, listing.id);
                        },
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite ? Colors.red : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (listing.createdAt != null)
                      Text(
                        '${listing.createdAt!.day}.${listing.createdAt!.month}.${listing.createdAt!.year}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: listing.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: listing.images.first,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: Colors.grey.shade200,
                                width: 60,
                                height: 60,
                              ),
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                size: 24,
                                color: Colors.grey,
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    listingCategoryColor(listing.category),
                                    listingCategoryColor(
                                      listing.category,
                                    ).withValues(alpha: 0.72),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  listingCategoryIcon(listing.category),
                                  size: 26,
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  listing.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  listing.salary,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
