import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/shared/providers/paginated_listings_provider.dart';
import 'package:otelcim/shared/services/listing_service.dart';

class MockListingService extends Mock implements ListingService {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Object?> {}

const params = (
  category: null,
  searchQuery: null,
  city: null,
  region: null,
  minSalaryTl: null,
  maxSalaryTl: null,
  dateFilter: ListingDateFilter.all,
  employmentType: null,
  sortOrder: ListingSortOrder.newest,
  season: null,
);

Listing listing(String id) => Listing(
  id: id,
  posterId: 'u',
  posterName: 'Otel',
  title: id,
  description: 'D',
  category: 'diger',
  location: 'Antalya',
  salary: '1 TL',
  contactInfo: 'x',
);

void main() {
  setUpAll(() {
    registerFallbackValue(ListingDateFilter.all);
    registerFallbackValue(ListingSortOrder.newest);
    registerFallbackValue(MockDocumentSnapshot());
  });

  late MockListingService service;
  setUp(() => service = MockListingService());

  test('loadInitial publishes listings and cursor', () async {
    final cursor = MockDocumentSnapshot();
    when(
      () => service.getPaginatedListings(
        category: any(named: 'category'),
        searchQuery: any(named: 'searchQuery'),
        city: any(named: 'city'),
        region: any(named: 'region'),
        minSalaryTl: any(named: 'minSalaryTl'),
        maxSalaryTl: any(named: 'maxSalaryTl'),
        dateFilter: any(named: 'dateFilter'),
        employmentType: any(named: 'employmentType'),
        sortOrder: any(named: 'sortOrder'),
      ),
    ).thenAnswer(
      (_) async => PaginatedListingsResult(
        listings: [listing('1')],
        lastDocument: cursor,
        hasMore: true,
      ),
    );
    final notifier = PaginatedListingsNotifier(service, params);
    await notifier.loadInitial();
    expect(notifier.state.listings.single.id, '1');
    expect(notifier.state.hasMore, isTrue);
    expect(notifier.state.isLoading, isFalse);
  });

  test('loadMore appends and refresh resets then reloads', () async {
    final cursor = MockDocumentSnapshot();
    var initialCalls = 0;
    when(
      () => service.getPaginatedListings(
        category: any(named: 'category'),
        searchQuery: any(named: 'searchQuery'),
        city: any(named: 'city'),
        region: any(named: 'region'),
        minSalaryTl: any(named: 'minSalaryTl'),
        maxSalaryTl: any(named: 'maxSalaryTl'),
        dateFilter: any(named: 'dateFilter'),
        employmentType: any(named: 'employmentType'),
        sortOrder: any(named: 'sortOrder'),
      ),
    ).thenAnswer((_) async {
      initialCalls++;
      return PaginatedListingsResult(
        listings: [listing('1')],
        lastDocument: cursor,
        hasMore: true,
      );
    });
    when(
      () => service.getNextPage(
        lastDocument: any(named: 'lastDocument'),
        category: any(named: 'category'),
        searchQuery: any(named: 'searchQuery'),
        city: any(named: 'city'),
        region: any(named: 'region'),
        minSalaryTl: any(named: 'minSalaryTl'),
        maxSalaryTl: any(named: 'maxSalaryTl'),
        dateFilter: any(named: 'dateFilter'),
        employmentType: any(named: 'employmentType'),
        sortOrder: any(named: 'sortOrder'),
      ),
    ).thenAnswer(
      (_) async => PaginatedListingsResult(
        listings: [listing('2')],
        lastDocument: cursor,
        hasMore: false,
      ),
    );
    final notifier = PaginatedListingsNotifier(service, params);
    await notifier.loadInitial();
    await notifier.loadMore();
    expect(notifier.state.listings.map((e) => e.id), ['1', '2']);
    await notifier.refresh();
    expect(notifier.state.listings.single.id, '1');
    expect(initialCalls, 2);
  });
}
