import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/shared/providers/paginated_listings_provider.dart';
import 'package:otelcim/shared/services/listing_service.dart';

class MockListingService extends Mock implements ListingService {}

// ignore: subtype_of_sealed_class
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
  posterId: 'poster',
  posterName: 'Otel',
  title: id,
  description: 'Açıklama',
  category: 'resepsiyon',
  location: 'Antalya',
  salary: '35.000 TL',
  contactInfo: 'contact',
);

void stubInitial(
  MockListingService service,
  Future<PaginatedListingsResult> Function() answer,
) {
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
      season: any(named: 'season'),
    ),
  ).thenAnswer((_) => answer());
}

void main() {
  setUpAll(() {
    registerFallbackValue(ListingDateFilter.all);
    registerFallbackValue(ListingSortOrder.newest);
    registerFallbackValue(MockDocumentSnapshot());
  });

  late MockListingService service;

  setUp(() {
    service = MockListingService();
  });

  test('loadInitial clears loading and publishes a service failure without losing state', () async {
    stubInitial(service, () async => throw StateError('temporary read failure'));
    final notifier = PaginatedListingsNotifier(service, params);

    await notifier.loadInitial();

    expect(notifier.state.listings, isEmpty);
    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.hasMore, isTrue);
  });

  test('a second loadInitial while the first is pending does not duplicate the request', () async {
    final pending = Completer<PaginatedListingsResult>();
    stubInitial(service, () => pending.future);
    final notifier = PaginatedListingsNotifier(service, params);

    final first = notifier.loadInitial();
    await Future<void>.delayed(Duration.zero);
    final second = notifier.loadInitial();

    expect(notifier.state.isLoading, isTrue);
    pending.complete(
      PaginatedListingsResult(
        listings: [listing('one')],
        lastDocument: null,
        hasMore: false,
      ),
    );
    await Future.wait([first, second]);

    verify(
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
        season: any(named: 'season'),
      ),
    ).called(1);
    expect(notifier.state.listings.single.id, 'one');
    expect(notifier.state.isLoading, isFalse);
  });

  test('loadMore is a no-op when there is no cursor or no next page', () async {
    stubInitial(
      service,
      () async => PaginatedListingsResult(
        listings: [listing('one')],
        lastDocument: null,
        hasMore: false,
      ),
    );
    final notifier = PaginatedListingsNotifier(service, params);
    await notifier.loadInitial();
    await notifier.loadMore();

    verifyNever(
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
        season: any(named: 'season'),
      ),
    );
    expect(notifier.state.listings.single.id, 'one');
  });

  test('loadMore failure keeps existing listings and clears loading', () async {
    final cursor = MockDocumentSnapshot();
    stubInitial(
      service,
      () async => PaginatedListingsResult(
        listings: [listing('one')],
        lastDocument: cursor,
        hasMore: true,
      ),
    );
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
        season: any(named: 'season'),
      ),
    ).thenThrow(StateError('temporary page failure'));

    final notifier = PaginatedListingsNotifier(service, params);
    await notifier.loadInitial();
    await notifier.loadMore();

    expect(notifier.state.listings.map((item) => item.id), ['one']);
    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.hasMore, isTrue);
  });
}
