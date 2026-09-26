import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/categories.dart';
import '../../../../shared/constants/listing_filters.dart';
import '../../../../shared/error/error_mapper.dart';
import '../../../../shared/error/error_reporter.dart';
import '../../../../shared/services/listing_service.dart';
import '../../../discovery/domain/tourism_region.dart';
import '../../../listings/presentation/listing_filter_labels.dart';
import '../../../listings/presentation/season_utils.dart';

/// The advanced filters selected on the home discovery screen.
class HomeAdvancedFilters {
  const HomeAdvancedFilters({
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

  String salaryLabel(AppLocalizations l10n) {
    if (minSalaryTl != null && maxSalaryTl != null) {
      return '$minSalaryTl - $maxSalaryTl TL';
    }
    if (minSalaryTl != null) return l10n.salaryMinAndUp('$minSalaryTl');
    return l10n.salaryMaxAndDown('$maxSalaryTl');
  }

  HomeAdvancedFilters copyWith({
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
  }) => HomeAdvancedFilters(
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

/// Reusable advanced filters form for the mobile sheet and desktop sidebar.
///
/// In compact mode the form owns the scrollable middle section while its
/// action row remains visible at the bottom of the panel.
class ListingFiltersPanel extends ConsumerStatefulWidget {
  const ListingFiltersPanel({
    super.key,
    required this.initial,
    required this.listingService,
    required this.onApply,
    this.onReset,
    this.compact = false,
  });

  final HomeAdvancedFilters initial;
  final ListingService listingService;
  final ValueChanged<HomeAdvancedFilters> onApply;
  final VoidCallback? onReset;
  final bool compact;

  @override
  ConsumerState<ListingFiltersPanel> createState() =>
      _ListingFiltersPanelState();
}

class _ListingFiltersPanelState extends ConsumerState<ListingFiltersPanel> {
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
    unawaited(_loadLiveCounts());
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
    } on Object catch (error, stackTrace) {
      final failure = mapToFailure(error);
      logError(
        error,
        stackTrace,
        context: '_ListingFiltersPanelState._loadLiveCounts: ${failure.message}',
      );
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

  HomeAdvancedFilters _currentFilters() {
    return HomeAdvancedFilters(
      city: _city,
      region: _region,
      minSalaryTl: int.tryParse(_minController.text.trim()),
      maxSalaryTl: int.tryParse(_maxController.text.trim()),
      dateFilter: _date,
      employmentType: _employmentType,
      sortOrder: _sort,
      season: _season,
    );
  }

  void _apply() {
    final min = int.tryParse(_minController.text.trim());
    final max = int.tryParse(_maxController.text.trim());
    if (min != null && max != null && min > max) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.salaryRangeError)),
      );
      return;
    }
    ref.read(selectedCategoryFilterProvider.notifier).state = _category;
    widget.onApply(_currentFilters());
  }

  void _reset() {
    ref.read(selectedCategoryFilterProvider.notifier).state = null;
    setState(() {
      _city = null;
      _region = null;
      _category = null;
      _minController.clear();
      _maxController.clear();
      _date = ListingDateFilter.all;
      _employmentType = null;
      _sort = ListingSortOrder.newest;
      _season = null;
    });
    widget.onReset?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fields = _buildFields(context, l10n);
    final actions = _buildActions(context, l10n);

    if (widget.compact) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.filtersTooltip,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: fields,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: actions,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.advancedFiltersTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            fields,
            const SizedBox(height: AppSpacing.xl),
            actions,
          ],
        ),
      ),
    );
  }

  Widget _buildFields(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: _city,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.cityOrRegionLabel),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(l10n.allCitiesOption),
            ),
            ...turkishTourismCities.map(
              (city) => DropdownMenuItem(value: city, child: Text(city)),
            ),
          ],
          onChanged: (value) => setState(() => _city = value),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<ListingCategory?>(
          initialValue: _category,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.jobBranchLabel),
          items: [
            DropdownMenuItem<ListingCategory?>(
              value: null,
              child: Text(l10n.allBranchesOption),
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
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String?>(
          initialValue: _region,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.regionLabel),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(l10n.regionsTitle),
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
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.minSalaryLabel),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _maxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.maxSalaryLabel),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<ListingDateFilter>(
          initialValue: _date,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.listingDateLabel),
          items: ListingDateFilter.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(listingDateFilterLabel(l10n, value)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _date = value);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<EmploymentType?>(
          initialValue: _employmentType,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.employmentTypeLabel),
          items: [
            DropdownMenuItem<EmploymentType?>(
              value: null,
              child: Text(l10n.allEmploymentTypesOption),
            ),
            ...EmploymentType.values.map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(employmentTypeLabel(l10n, value)),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _employmentType = value),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<ListingSeason?>(
          initialValue: _season,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.seasonLabel),
          items: [
            DropdownMenuItem<ListingSeason?>(
              value: null,
              child: Text(l10n.seasonAny),
            ),
            ...ListingSeason.values.map(
              (season) => DropdownMenuItem(
                value: season,
                child: Text(
                  _withCount(
                    listingSeasonLabel(l10n, season.code),
                    _seasonCounts[season.code],
                  ),
                ),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _season = value),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<ListingSortOrder>(
          initialValue: _sort,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.sortLabel),
          items: ListingSortOrder.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(listingSortOrderLabel(l10n, value)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _sort = value);
          },
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _reset,
            child: Text(l10n.clearFiltersAction),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FilledButton(
            onPressed: _apply,
            child: Text(l10n.applyFiltersAction),
          ),
        ),
      ],
    );
  }
}
