import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../../listings/presentation/listing_filter_labels.dart';
import '../../listings/presentation/season_utils.dart';
import '../../../core/responsive/responsive_layout.dart';
import 'widgets/home_screen_widgets.dart';
import 'widgets/listing_feed_card.dart';

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
      unawaited(
        Future.microtask(
          () =>
              ref.read(notificationServiceProvider).selectRegion(initialRegion),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_columnCountInitialized) {
      _columnCountInitialized = true;
      final width = MediaQuery.sizeOf(context).width;
      // Phones read best as a single list; wider screens get 2-3 columns of
      // the same text-first card.
      if (width >= desktopBreakpoint) {
        _columnCount = 3;
      } else if (width >= tabletBreakpoint) {
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
      unawaited(
        ref.read(paginatedListingsProvider(_currentParams).notifier).loadMore(),
      );
    }
  }

  Future<void> _onRefresh() async {
    await ref
        .read(paginatedListingsProvider(_currentParams).notifier)
        .refresh();

    if (_scrollController.hasClients) {
      unawaited(
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
      );
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
    final l10n = AppLocalizations.of(context)!;
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
        paginationState.error == null &&
        paginationState.hasMore) {
      final notifier = ref.read(
        paginatedListingsProvider(_currentParams).notifier,
      );
      unawaited(Future.microtask(notifier.loadInitial));
    }

    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(
                widget.initialRegion == null
                    ? AppLocalizations.of(context)!.appName
                    : (Localizations.localeOf(context).languageCode == 'en'
                              ? tourismRegionById(widget.initialRegion)?.nameEn
                              : tourismRegionById(
                                  widget.initialRegion,
                                )?.nameTr) ??
                          AppLocalizations.of(context)!.regionsTitle,
              ),
              actions: [
                IconButton(
                  onPressed: () => context.push('/seasonal-calendar'),
                  tooltip: l10n.seasonalCalendarTooltip,
                  icon: const Icon(Icons.calendar_month_rounded),
                ),
                IconButton(
                  onPressed: () => context.push('/regions'),
                  tooltip: l10n.regionsTitle,
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
                            hintText: l10n.homeSearchHint,
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF495057),
                            ),
                            suffixIcon: _hasSearchText
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 20,
                                    ),
                                    tooltip: 'Aramayı Temizle',
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 48,
                                    ),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Badge(
                      isLabelVisible: _filters.activeCount > 0,
                      label: Text(
                        '${_filters.activeCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: IconButton.filledTonal(
                        onPressed: _openFilters,
                        tooltip: l10n.filtersTooltip,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
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
                          _filters.salaryLabel(l10n),
                          () => setState(
                            () =>
                                _filters = _filters.copyWith(clearSalary: true),
                          ),
                        ),
                      if (_filters.dateFilter != ListingDateFilter.all)
                        _filterChip(
                          listingDateFilterLabel(l10n, _filters.dateFilter),
                          () => setState(
                            () => _filters = _filters.copyWith(
                              dateFilter: ListingDateFilter.all,
                            ),
                          ),
                        ),
                      if (_filters.employmentType != null)
                        _filterChip(
                          employmentTypeLabel(l10n, _filters.employmentType!),
                          () => setState(
                            () => _filters = _filters.copyWith(
                              clearEmploymentType: true,
                            ),
                          ),
                        ),
                      if (_filters.season != null)
                        _filterChip(
                          listingSeasonLabel(l10n, _filters.season!.code),
                          () => setState(
                            () =>
                                _filters = _filters.copyWith(clearSeason: true),
                          ),
                        ),
                      if (_filters.sortOrder != ListingSortOrder.newest)
                        _filterChip(
                          listingSortOrderLabel(l10n, _filters.sortOrder),
                          () => setState(
                            () => _filters = _filters.copyWith(
                              sortOrder: ListingSortOrder.newest,
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: () => setState(
                          () => _filters = const HomeAdvancedFilters(),
                        ),
                        child: Text(l10n.clearFiltersAction),
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
                        label: Text(l10n.allFilterChip),
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
                      l10n.resultCount(paginationState.listings.length),
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
                            final tooltip = l10n.gridColumnsTooltip(cols);
                            return Semantics(
                              button: true,
                              label: tooltip,
                              child: Tooltip(
                                message: tooltip,
                                child: InkWell(
                                  key: Key('grid_col_$cols'),
                                  onTap: () => setState(() {
                                    _isTableView = false;
                                    _columnCount = cols;
                                  }),
                                  borderRadius: BorderRadius.circular(6),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 48,
                                    ),
                                    child: Center(
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                                  : const Color(0xFF495057),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '$cols',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : const Color(0xFF495057),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          Semantics(
                            button: true,
                            label: l10n.tableViewTooltip,
                            child: Tooltip(
                              message: l10n.tableViewTooltip,
                              child: InkWell(
                                key: const Key('grid_col_table'),
                                onTap: () =>
                                    setState(() => _isTableView = true),
                                borderRadius: BorderRadius.circular(6),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  child: Center(
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isTableView
                                            ? Theme.of(context).primaryColor
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.table_rows_rounded,
                                        size: 18,
                                        color: _isTableView
                                            ? Colors.white
                                            : const Color(0xFF495057),
                                      ),
                                    ),
                                  ),
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
              ListingsSkeletonSliver(
                columnCount: _isTableView ? 1 : _columnCount,
              )
            else if (paginationState.error != null &&
                paginationState.listings.isEmpty)
              _buildErrorState(context)
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
                            child: ListingFeedCard(
                              listing: paginationState.listings[index],
                            ),
                          ),
                          childCount: paginationState.listings.length,
                        ),
                      )
                    // Text-first cards vary in height, so rows of equal-height
                    // cells instead of a fixed-aspect SliverGrid.
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, row) {
                            final cells = paginationState.listings
                                .skip(row * _columnCount)
                                .take(_columnCount)
                                .toList();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (var i = 0; i < _columnCount; i++) ...[
                                      if (i > 0) const SizedBox(width: 12),
                                      Expanded(
                                        child: i < cells.length
                                            ? ListingFeedCard(listing: cells[i])
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount:
                              (paginationState.listings.length +
                                  _columnCount -
                                  1) ~/
                              _columnCount,
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
    final l10n = AppLocalizations.of(context)!;
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
              Text(
                l10n.noListingsTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noListingsBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),
              if (kDebugMode) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(listingServiceProvider).seedSampleListings();
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: Text(l10n.seedSampleListingsAction),
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
              ],
              OutlinedButton.icon(
                onPressed: () => context.push('/create-listing'),
                icon: const Icon(Icons.add_circle_outline),
                label: Text(l10n.createFirstListingAction),
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

  Widget _buildErrorState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.listingsLoadError,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(paginatedListingsProvider(_currentParams).notifier)
                    .refresh(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retryButton),
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
