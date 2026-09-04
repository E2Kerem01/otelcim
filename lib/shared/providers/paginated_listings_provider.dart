import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/listings/domain/listing_model.dart';
import '../constants/listing_filters.dart';
import '../error/error_mapper.dart';
import '../error/error_reporter.dart';
import '../services/listing_service.dart';

/// State class for paginated listings
class PaginatedListingsState {
  final List<Listing> listings;
  final bool hasMore;
  final bool isLoading;
  final DocumentSnapshot? lastDocument;

  const PaginatedListingsState({
    required this.listings,
    required this.hasMore,
    required this.isLoading,
    this.lastDocument,
  });

  PaginatedListingsState copyWith({
    List<Listing>? listings,
    bool? hasMore,
    bool? isLoading,
    DocumentSnapshot? lastDocument,
  }) {
    return PaginatedListingsState(
      listings: listings ?? this.listings,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}

/// StateNotifier for managing paginated listings
class PaginatedListingsNotifier extends StateNotifier<PaginatedListingsState> {
  PaginatedListingsNotifier(this._listingService, this.params)
    : super(
        const PaginatedListingsState(
          listings: [],
          hasMore: true,
          isLoading: false,
        ),
      );

  final ListingService _listingService;
  final PaginationParams params;

  /// Load initial batch of listings
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await _listingService.getPaginatedListings(
        category: params.category,
        searchQuery: params.searchQuery,
        city: params.city,
        region: params.region,
        minSalaryTl: params.minSalaryTl,
        maxSalaryTl: params.maxSalaryTl,
        dateFilter: params.dateFilter,
        employmentType: params.employmentType,
        sortOrder: params.sortOrder,
        season: params.season,
      );

      state = PaginatedListingsState(
        listings: result.listings,
        hasMore: result.hasMore,
        isLoading: false,
        lastDocument: result.lastDocument,
      );
    } on Object catch (error, stackTrace) {
      final failure = mapToFailure(error);
      logError(
        error,
        stackTrace,
        context: 'PaginatedListingsNotifier.loadInitial: ${failure.message}',
      );
      state = state.copyWith(isLoading: false);
    }
  }

  /// Load next batch of listings
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.lastDocument == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await _listingService.getNextPage(
        lastDocument: state.lastDocument!,
        category: params.category,
        searchQuery: params.searchQuery,
        city: params.city,
        region: params.region,
        minSalaryTl: params.minSalaryTl,
        maxSalaryTl: params.maxSalaryTl,
        dateFilter: params.dateFilter,
        employmentType: params.employmentType,
        sortOrder: params.sortOrder,
        season: params.season,
      );

      state = PaginatedListingsState(
        listings: [...state.listings, ...result.listings],
        hasMore: result.hasMore,
        isLoading: false,
        lastDocument: result.lastDocument,
      );
    } on Object catch (error, stackTrace) {
      final failure = mapToFailure(error);
      logError(
        error,
        stackTrace,
        context: 'PaginatedListingsNotifier.loadMore: ${failure.message}',
      );
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refresh listings (reset and reload from beginning)
  Future<void> refresh() async {
    state = const PaginatedListingsState(
      listings: [],
      hasMore: true,
      isLoading: false,
    );
    await loadInitial();
  }
}

/// Provider for paginated listings with category and search parameters
typedef PaginationParams = ({
  String? category,
  String? searchQuery,
  String? city,
  String? region,
  int? minSalaryTl,
  int? maxSalaryTl,
  ListingDateFilter dateFilter,
  EmploymentType? employmentType,
  ListingSortOrder sortOrder,
  String? season,
});

final paginatedListingsProvider =
    StateNotifierProvider.family<
      PaginatedListingsNotifier,
      PaginatedListingsState,
      PaginationParams
    >((ref, params) {
      return PaginatedListingsNotifier(
        ref.watch(listingServiceProvider),
        params,
      );
    });
