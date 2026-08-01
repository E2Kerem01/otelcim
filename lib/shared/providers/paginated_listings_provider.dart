import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/listings/domain/listing_model.dart';
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
  PaginatedListingsNotifier(this._listingService, {this.category, this.searchQuery})
      : super(const PaginatedListingsState(
          listings: [],
          hasMore: true,
          isLoading: false,
        ));

  final ListingService _listingService;
  final String? category;
  final String? searchQuery;

  /// Load initial batch of listings
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await _listingService.getPaginatedListings(
        category: category,
        searchQuery: searchQuery,
      );

      state = PaginatedListingsState(
        listings: result.listings,
        hasMore: result.hasMore,
        isLoading: false,
        lastDocument: result.lastDocument,
      );
    } catch (e) {
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
        category: category,
        searchQuery: searchQuery,
      );

      state = PaginatedListingsState(
        listings: [...state.listings, ...result.listings],
        hasMore: result.hasMore,
        isLoading: false,
        lastDocument: result.lastDocument,
      );
    } catch (e) {
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
typedef _PaginationParams = ({String? category, String? searchQuery});

final paginatedListingsProvider = StateNotifierProvider.family<PaginatedListingsNotifier, PaginatedListingsState, _PaginationParams>(
  (ref, params) {
    return PaginatedListingsNotifier(
      ref.watch(listingServiceProvider),
      category: params.category,
      searchQuery: params.searchQuery,
    );
  },
);
