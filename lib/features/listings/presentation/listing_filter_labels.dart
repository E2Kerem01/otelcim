import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/categories.dart';
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

String listingCategoryLabelFor(AppLocalizations l10n, String categoryName) {
  final category = ListingCategory.values.firstWhere(
    (value) => value.name == categoryName,
    orElse: () => ListingCategory.diger,
  );
  return switch (category) {
    ListingCategory.resepsiyon => l10n.categoryReception,
    ListingCategory.onburoIliskiler => l10n.listingCategoryGuestRelations,
    ListingCategory.katHizmetleri => l10n.categoryHousekeeping,
    ListingCategory.mutfakAsci => l10n.categoryKitchenChef,
    ListingCategory.pastaneSteward => l10n.listingCategoryBakerySteward,
    ListingCategory.servisGarson => l10n.categoryServiceWaiter,
    ListingCategory.barBarmen => l10n.listingCategoryBarBartender,
    ListingCategory.guvenlik => l10n.categorySecurity,
    ListingCategory.saglik => l10n.listingCategoryHealth,
    ListingCategory.animasyon => l10n.categoryAnimation,
    ListingCategory.cocukKulubu => l10n.listingCategoryKidsClub,
    ListingCategory.spaWellness => l10n.listingCategorySpaWellness,
    ListingCategory.havuzPlaj => l10n.listingCategoryPoolBeach,
    ListingCategory.rezervasyonSatis => l10n.listingCategoryReservationsSales,
    ListingCategory.yonetim => l10n.categoryManagement,
    ListingCategory.muhasebeIk => l10n.listingCategoryAccountingHr,
    ListingCategory.depoAmbar => l10n.listingCategoryWarehouse,
    ListingCategory.teknikServis => l10n.categoryTechnicalService,
    ListingCategory.bahcePeyzaj => l10n.listingCategoryLandscaping,
    ListingCategory.ulasimSofor => l10n.listingCategoryTransportDriver,
    ListingCategory.stajyer => l10n.listingCategoryIntern,
    ListingCategory.diger => l10n.categoryOther,
  };
}

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
