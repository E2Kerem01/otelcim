import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/constants/categories.dart';
import '../../../shared/constants/listing_filters.dart';
import '../../../shared/providers/paginated_listings_provider.dart';
import '../../../shared/services/listing_service.dart';
import '../../../shared/services/notification_service.dart';
import '../../ads/presentation/widgets/banner_ad_carousel.dart';
import '../../../l10n/app_localizations.dart';
import '../../discovery/domain/tourism_region.dart';
import '../../../core/responsive/responsive_layout.dart';
import 'widgets/home_screen_widgets.dart';

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
  bool _isTableView = false;
  HomeAdvancedFilters _filters = const HomeAdvancedFilters();
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
    _filters = HomeAdvancedFilters(region: widget.initialRegion);
    _scrollController.addListener(_onScroll);
    final initialRegion = widget.initialRegion;
    if (initialRegion != null) {
      unawaited(Future.microtask(
        () => ref.read(notificationServiceProvider).selectRegion(initialRegion),
      ));
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
      unawaited(ref.read(paginatedListingsProvider(_currentParams).notifier).loadMore());
    }
  }

  Future<void> _onRefresh() async {
    await ref
        .read(paginatedListingsProvider(_currentParams).notifier)
        .refresh();

    if (_scrollController.hasClients) {
      unawaited(_scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ));
    }
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<HomeAdvancedFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FilterSheet(
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
      unawaited(Future.microtask(notifier.loadInitial));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialRegion == null
              ? AppLocalizations.of(context)!.appName
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
                            setState(() => _filters = const HomeAdvancedFilters()),
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
                        children: [
                          ...availableColumnCounts.map((cols) {
                            final isSelected =
                                !_isTableView && _columnCount == cols;
                            return Tooltip(
                              message: '$cols Sütun',
                              child: InkWell(
                                key: Key('grid_col_$cols'),
                                onTap: () => setState(() {
                                  _isTableView = false;
                                  _columnCount = cols;
                                }),
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
                          }),
                          Tooltip(
                            message: 'Tablo Görünümü',
                            child: InkWell(
                              key: const Key('grid_col_table'),
                              onTap: () =>
                                  setState(() => _isTableView = true),
                              borderRadius: BorderRadius.circular(6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _isTableView
                                      ? Theme.of(context).primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.table_rows_rounded,
                                  size: 16,
                                  color: _isTableView
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (paginationState.isLoading && paginationState.listings.isEmpty)
              ListingsSkeletonSliver(columnCount: _isTableView ? 1 : _columnCount)
            else if (paginationState.listings.isEmpty)
              _buildEmptyState(context)
            else ...[
              if (_isTableView)
                const SliverToBoxAdapter(child: ListingTableHeader()),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: _isTableView
                    ? SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListingTableRow(
                              listing: paginationState.listings[index],
                            ),
                          ),
                          childCount: paginationState.listings.length,
                        ),
                      )
                    : _columnCount == 1
                    ? SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ListingCard(
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
                          (context, index) => ListingCard(
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

