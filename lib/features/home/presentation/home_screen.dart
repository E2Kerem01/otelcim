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
import '../../listings/domain/listing_model.dart';
import '../../listings/presentation/listing_filter_labels.dart';
import '../../listings/presentation/widgets/listing_preview_pane.dart';
import '../../listings/presentation/season_utils.dart';
import '../../../app/design_tokens.dart';
import '../../../core/responsive/max_width_container.dart';
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
  String? _selectedListingId;
  bool _selectionInitialized = false;
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
    if (!_selectionInitialized) {
      _selectionInitialized = true;
      try {
        _selectedListingId =
            GoRouterState.of(context).uri.queryParameters['selected'];
      } on Object catch (_) {
        // HomeScreen is also used directly in widget tests and embedded flows.
      }
    }
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

  void _selectListing(String listingId) {
    if (_selectedListingId == listingId) return;
    setState(() => _selectedListingId = listingId);
    _replaceSelectedListingQuery(listingId);
  }

  void _clearSelectedListing() {
    if (_selectedListingId == null) return;
    setState(() => _selectedListingId = null);
    try {
      final currentUri = GoRouterState.of(context).uri;
      final queryParameters = Map<String, String>.from(
        currentUri.queryParameters,
      )..remove('selected');
      unawaited(
        GoRouter.of(context).replace<void>(
          Uri(path: '/', queryParameters: queryParameters).toString(),
        ),
      );
    } on Object catch (_) {
      // A standalone HomeScreen has no router; selection still clears locally.
    }
  }

  void _replaceSelectedListingQuery(String listingId) {
    try {
      final currentUri = GoRouterState.of(context).uri;
      final queryParameters = Map<String, String>.from(
        currentUri.queryParameters,
      )..['selected'] = listingId;
      final uri = Uri(path: '/', queryParameters: queryParameters);
      unawaited(GoRouter.of(context).replace<void>(uri.toString()));
    } on Object catch (_) {
      // A standalone HomeScreen has no router; selection still works locally.
    }
  }

  void _ensureSelectedListing(List<Listing> listings) {
    if (listings.isEmpty) return;
    final selected = listings.any((listing) => listing.id == _selectedListingId)
        ? _selectedListingId
        : listings.first.id;
    if (_selectedListingId == selected) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedListingId == selected) return;
      setState(() => _selectedListingId = selected);
      _replaceSelectedListingQuery(selected!);
    });
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
    final mobileBody = MaxWidthContainer(
      maxWidth: AppBreakpoints.contentMaxWidth,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: _buildMobileSlivers(
            context,
            l10n,
            selectedCategory,
            paginationState,
            isDesktop,
            availableColumnCounts,
          ),
        ),
      ),
    );

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 1024) {
            return _buildDesktopBody(
              context,
              l10n,
              selectedCategory,
              paginationState,
              constraints.maxWidth >= 1280,
              availableColumnCounts,
            );
          }
          return mobileBody;
        },
      ),
/*              if (isDesktop)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      widget.initialRegion == null
                          ? l10n.appName
                          : ((Localizations.localeOf(context).languageCode ==
                                        'en'
                                    ? tourismRegionById(
                                        widget.initialRegion,
                                      )?.nameEn
                                    : tourismRegionById(
                                        widget.initialRegion,
                                      )?.nameTr) ??
                                l10n.regionsTitle),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
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
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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
                              () =>
                                  _filters = _filters.copyWith(clearCity: true),
                            ),
                          ),
                        if (_filters.region != null)
                          _filterChip(
                            (Localizations.localeOf(context).languageCode ==
                                        'en'
                                    ? tourismRegionById(_filters.region)?.nameEn
                                    : tourismRegionById(
                                        _filters.region,
                                      )?.nameTr) ??
                                _filters.region!,
                            () => setState(
                              () => _filters = _filters.copyWith(
                                clearRegion: true,
                              ),
                            ),
                          ),
                        if (_filters.minSalaryTl != null ||
                            _filters.maxSalaryTl != null)
                          _filterChip(
                            _filters.salaryLabel(l10n),
                            () => setState(
                              () => _filters = _filters.copyWith(
                                clearSalary: true,
                              ),
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
                              () => _filters = _filters.copyWith(
                                clearSeason: true,
                              ),
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
                                    .read(
                                      selectedCategoryFilterProvider.notifier,
                                    )
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
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                      for (
                                        var i = 0;
                                        i < _columnCount;
                                        i++
                                      ) ...[
                                        if (i > 0) const SizedBox(width: 12),
                                        Expanded(
                                          child: i < cells.length
                                              ? ListingFeedCard(
                                                  listing: cells[i],
                                                )
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
      ),*/
    );
  }

  List<Widget> _buildMobileSlivers(
    BuildContext context,
    AppLocalizations l10n,
    ListingCategory? selectedCategory,
    PaginatedListingsState paginationState,
    bool isDesktop,
    List<int> availableColumnCounts,
  ) {
    return [
      if (isDesktop)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              widget.initialRegion == null
                  ? l10n.appName
                  : ((Localizations.localeOf(context).languageCode == 'en'
                            ? tourismRegionById(widget.initialRegion)?.nameEn
                            : tourismRegionById(widget.initialRegion)?.nameTr) ??
                        l10n.regionsTitle),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppElevation.softShadow,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.homeSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _hasSearchText
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              tooltip: l10n.clearFiltersAction,
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Badge(
                isLabelVisible: _filters.activeCount > 0,
                label: Text('${_filters.activeCount}'),
                child: IconButton.filledTonal(
                  onPressed: _openFilters,
                  tooltip: l10n.filtersTooltip,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: FilledButton.tonalIcon(
            onPressed: () => context.push('/nearby'),
            icon: const Icon(Icons.near_me_outlined),
            label: Text(l10n.nearMe),
          ),
        ),
      ),
      if (_filters.activeCount > 0)
        SliverToBoxAdapter(child: _buildActiveFilterChips(context, l10n)),
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: BannerAdCarousel(),
        ),
      ),
      SliverToBoxAdapter(child: _buildCategoryChips(context, l10n, selectedCategory)),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text(
                l10n.resultCount(paginationState.listings.length),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              _buildGridControls(context, l10n, availableColumnCounts),
            ],
          ),
        ),
      ),
      ..._buildListingSlivers(
        context,
        paginationState,
        columnCount: _columnCount,
        allowSelection: false,
      ),
    ];
  }

  Widget _buildDesktopBody(
    BuildContext context,
    AppLocalizations l10n,
    ListingCategory? selectedCategory,
    PaginatedListingsState paginationState,
    bool showPreview,
    List<int> availableColumnCounts,
  ) {
    if (showPreview) _ensureSelectedListing(paginationState.listings);
    final previewListingId = _selectedListingId ??
        (paginationState.listings.isEmpty
            ? null
            : paginationState.listings.first.id);
    final feedColumnCount = showPreview ? 1 : _columnCount;

    return MaxWidthContainer(
      maxWidth: 1320,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                widget.initialRegion == null
                    ? l10n.appName
                    : ((Localizations.localeOf(context).languageCode == 'en'
                              ? tourismRegionById(widget.initialRegion)?.nameEn
                              : tourismRegionById(widget.initialRegion)?.nameTr) ??
                          l10n.regionsTitle),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildDesktopSearch(context, l10n),
          if (_filters.activeCount > 0)
            _buildActiveFilterChips(context, l10n),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 280,
                    child: ListingFiltersPanel(
                      initial: _filters,
                      listingService: ref.read(listingServiceProvider),
                      compact: true,
                      onApply: (filters) async {
                        setState(() => _filters = filters);
                        if (filters.region != null) {
                          await ref
                              .read(notificationServiceProvider)
                              .selectRegion(filters.region!);
                        }
                      },
                      onReset: () => setState(
                        () => _filters = const HomeAdvancedFilters(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: _buildDesktopFeed(
                      context,
                      l10n,
                      selectedCategory,
                      paginationState,
                      feedColumnCount,
                      availableColumnCounts,
                      showPreview,
                    ),
                  ),
                  if (showPreview) ...[
                    const SizedBox(width: AppSpacing.lg),
                    SizedBox(
                      width: 440,
                      child: previewListingId == null
                          ? const SizedBox.shrink()
                          : ListingPreviewPane(
                              listingId: previewListingId,
                              onClose: _clearSelectedListing,
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSearch(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppElevation.softShadow,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.homeSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _hasSearchText
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          tooltip: l10n.clearFiltersAction,
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.push('/nearby'),
            icon: const Icon(Icons.near_me_outlined),
            label: Text(l10n.nearMe),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFeed(
    BuildContext context,
    AppLocalizations l10n,
    ListingCategory? selectedCategory,
    PaginatedListingsState paginationState,
    int feedColumnCount,
    List<int> availableColumnCounts,
    bool showPreview,
  ) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: _buildCategoryChips(context, l10n, selectedCategory),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    l10n.resultCount(paginationState.listings.length),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (!showPreview)
                    _buildGridControls(context, l10n, availableColumnCounts),
                ],
              ),
            ),
          ),
          ..._buildListingSlivers(
            context,
            paginationState,
            columnCount: feedColumnCount,
            allowSelection: showPreview,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildListingSlivers(
    BuildContext context,
    PaginatedListingsState paginationState, {
    required int columnCount,
    required bool allowSelection,
  }) {
    if (paginationState.isLoading && paginationState.listings.isEmpty) {
      return [ListingsSkeletonSliver(columnCount: columnCount)];
    }
    if (paginationState.error != null && paginationState.listings.isEmpty) {
      return [_buildErrorState(context)];
    }
    if (paginationState.listings.isEmpty) {
      return [_buildEmptyState(context)];
    }

    if (_isTableView && !allowSelection) {
      final listings = paginationState.listings;
      return [
        const SliverToBoxAdapter(child: ListingTableHeader()),
        SliverPadding(
          padding: EdgeInsets.zero,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListingTableRow(listing: listings[index]),
              ),
              childCount: listings.length,
            ),
          ),
        ),
      ];
    }

    Widget card(Listing listing) => ListingFeedCard(
          listing: listing,
          isSelected: allowSelection && listing.id == _selectedListingId,
          onTap: allowSelection ? () => _selectListing(listing.id) : null,
        );

    final listings = paginationState.listings;
    final content = columnCount == 1
        ? SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: card(listings[index]),
              ),
              childCount: listings.length,
            ),
          )
        : SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, row) {
                final cells = listings
                    .skip(row * columnCount)
                    .take(columnCount)
                    .toList();
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var index = 0; index < columnCount; index++) ...[
                          if (index > 0)
                            const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: index < cells.length
                                ? card(cells[index])
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              childCount: (listings.length + columnCount - 1) ~/ columnCount,
            ),
          );

    return [
      SliverPadding(
        padding: EdgeInsets.zero,
        sliver: content,
      ),
      if (paginationState.isLoading)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ];
  }

  Widget _buildCategoryChips(
    BuildContext context,
    AppLocalizations l10n,
    ListingCategory? selectedCategory,
  ) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: ListingCategory.values.length + 1,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = index == 0
              ? null
              : ListingCategory.values[index - 1];
          final isSelected = category == selectedCategory;
          return ChoiceChip(
            label: Text(
              category == null
                  ? l10n.allFilterChip
                  : listingCategoryLabels[category]!,
            ),
            selected: isSelected,
            onSelected: (_) => ref
                    .read(selectedCategoryFilterProvider.notifier)
                    .state =
                category,
            selectedColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveFilterChips(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                      : tourismRegionById(_filters.region)?.nameTr) ??
                  _filters.region!,
              () => setState(
                () => _filters = _filters.copyWith(clearRegion: true),
              ),
            ),
          if (_filters.minSalaryTl != null || _filters.maxSalaryTl != null)
            _filterChip(
              _filters.salaryLabel(l10n),
              () => setState(
                () => _filters = _filters.copyWith(clearSalary: true),
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
                () => _filters = _filters.copyWith(clearEmploymentType: true),
              ),
            ),
          if (_filters.season != null)
            _filterChip(
              listingSeasonLabel(l10n, _filters.season!.code),
              () => setState(
                () => _filters = _filters.copyWith(clearSeason: true),
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
    );
  }

  Widget _buildGridControls(
    BuildContext context,
    AppLocalizations l10n,
    List<int> availableColumnCounts,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...availableColumnCounts.map((cols) {
            final isSelected = !_isTableView && _columnCount == cols;
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
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surface.withValues(alpha: 0),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          '$cols',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
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
                onTap: () => setState(() => _isTableView = true),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.table_rows_rounded,
                      color: _isTableView
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
              Icon(
                Icons.hotel_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
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
