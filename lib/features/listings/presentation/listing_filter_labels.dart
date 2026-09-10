import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/listing_filters.dart';

/// Localized display labels for the listing filter enums. The enums keep their
/// Turkish `label` getters for code paths not yet migrated to
/// [AppLocalizations]; call these helpers wherever a `BuildContext` is on hand.

String employmentTypeLabel(AppLocalizations l10n, EmploymentType type) =>
    switch (type) {
      EmploymentType.fullTime => l10n.employmentTypeFullTime,
      EmploymentType.partTime => l10n.employmentTypePartTime,
      EmploymentType.seasonal => l10n.employmentTypeSeasonal,
    };

String listingDateFilterLabel(AppLocalizations l10n, ListingDateFilter filter) =>
    switch (filter) {
      ListingDateFilter.all => l10n.dateFilterAll,
      ListingDateFilter.last24Hours => l10n.dateFilterLast24Hours,
      ListingDateFilter.lastWeek => l10n.dateFilterLastWeek,
      ListingDateFilter.lastMonth => l10n.dateFilterLastMonth,
    };

String listingSortOrderLabel(AppLocalizations l10n, ListingSortOrder order) =>
    switch (order) {
      ListingSortOrder.newest => l10n.sortOrderNewest,
      ListingSortOrder.salaryHighToLow => l10n.sortOrderSalaryHighToLow,
      ListingSortOrder.salaryLowToHigh => l10n.sortOrderSalaryLowToHigh,
    };
