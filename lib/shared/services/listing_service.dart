import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/listings/domain/listing_model.dart';
import '../constants/listing_filters.dart';

class ListingService {
  ListingService(this._db);

  final FirebaseFirestore _db;

  Stream<List<Listing>> watchActiveListings({
    String? category,
    String? searchQuery,
  }) {
    return _db
        .collection('listings')
        .snapshots()
        .map((snap) {
          var listings = snap.docs
              .map(Listing.fromDoc)
              .where((l) => l.status == ListingStatus.active)
              .toList();

          listings.sort((a, b) {
            final aBoosted =
                a.isBoosted &&
                (a.boostExpiresAt?.isAfter(DateTime.now()) ?? false);
            final bBoosted =
                b.isBoosted &&
                (b.boostExpiresAt?.isAfter(DateTime.now()) ?? false);
            if (aBoosted && !bBoosted) return -1;
            if (!aBoosted && bBoosted) return 1;
            final tA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tB.compareTo(tA);
          });

          if (category != null && category.isNotEmpty) {
            listings = listings.where((l) => l.category == category).toList();
          }

          if (searchQuery != null && searchQuery.isNotEmpty) {
            final q = searchQuery.toLowerCase();
            listings = listings
                .where(
                  (l) =>
                      l.title.toLowerCase().contains(q) ||
                      l.location.toLowerCase().contains(q) ||
                      l.description.toLowerCase().contains(q),
                )
                .toList();
          }

          return listings;
        })
        .handleError((error) {
          debugPrint('Firestore watchActiveListings warning: $error');
          return <Listing>[];
        });
  }

  Stream<List<Listing>> watchMyListings(String uid) {
    return _db
        .collection('listings')
        .snapshots()
        .map((snap) {
          var listings = snap.docs
              .map(Listing.fromDoc)
              .where((l) => l.posterId == uid)
              .toList();

          listings.sort((a, b) {
            final tA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tB.compareTo(tA);
          });

          return listings;
        })
        .handleError((error) {
          debugPrint('Firestore watchMyListings warning: $error');
          return <Listing>[];
        });
  }

  Future<void> seedSampleListings() async {
    try {
      final snap = await _db.collection('listings').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final samples = [
        {
          'posterId': 'system_demo',
          'posterName': 'Belek Luxury Resort',
          'title': 'Ön Büro Resepsiyonisti (İngilizce & Rusça Bilen)',
          'description':
              'Belek 5 Yıldızlı Otelimizde görevlendirilmek üzere diksiyonu düzgün, vardiyalı çalışabilecek resepsiyonist aranıyor. Lojman ve yemek mevcuttur.',
          'category': 'resepsiyon',
          'location': 'Antalya, Belek',
          'salary': '35.000 TL / Ay',
          'city': 'Antalya',
          'minSalaryTl': 35000,
          'maxSalaryTl': 35000,
          'employmentType': EmploymentType.fullTime.name,
          'contactInfo': 'ik@belekluxuryresort.com - 0242 555 01 02',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'posterId': 'system_demo',
          'posterName': 'Grand Palace Bosphorus',
          'title': 'Chef de Partie / Aşçıbaşı Yardımcısı',
          'description':
              'İstanbul Şişli lokasyonundaki otel mutfağımız için soğuk ve sıcak büfe tecrübeli aşçı ekibi aranmaktadır. SGK + Yemek + Prim.',
          'category': 'mutfak',
          'location': 'İstanbul, Şişli',
          'salary': '45.000 TL / Ay',
          'city': 'İstanbul',
          'minSalaryTl': 45000,
          'maxSalaryTl': 45000,
          'employmentType': EmploymentType.fullTime.name,
          'contactInfo': 'kariyer@grandpalace.com',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'posterId': 'system_demo',
          'posterName': 'Bodrum Sunset Beach Hotel',
          'title': 'Servis Elemanı & Garson (Sezonluk)',
          'description':
              'Bodrum Yalıkavak otelimizde beach ve alakart restoranda çalışacak enerjik servis elemanları aranıyor. Lojman ve dolgun bahşiş imkanı.',
          'category': 'servis',
          'location': 'Muğla, Bodrum',
          'salary': '30.000 TL / Ay + Tip',
          'city': 'Muğla',
          'minSalaryTl': 30000,
          'maxSalaryTl': 30000,
          'employmentType': EmploymentType.seasonal.name,
          'contactInfo': '0532 100 20 30',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'posterId': 'system_demo',
          'posterName': 'Cappadocia Cave Suites',
          'title': 'Kat Hizmetleri Görevlisi (Housekeeping)',
          'description':
              'Nevşehir Ürgüp bölgesindeki butik otelimizde oda temizliği ve düzeninden sorumlu deneyimli kat görevlileri alınacaktır.',
          'category': 'kat_hizmetleri',
          'location': 'Nevşehir, Ürgüp',
          'salary': '28.000 TL / Ay',
          'city': 'Nevşehir',
          'minSalaryTl': 28000,
          'maxSalaryTl': 28000,
          'employmentType': EmploymentType.fullTime.name,
          'contactInfo': 'info@cappadociacavesuites.com',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (final data in samples) {
        await _db.collection('listings').add(data);
      }
    } catch (e) {
      debugPrint('Error seeding sample listings: $e');
    }
  }

  Future<String> createListing(Listing listing) async {
    final ref = await _db.collection('listings').add(listing.toMap());
    return ref.id;
  }

  Future<List<String>> createBatchListings(List<Listing> listings) async {
    if (listings.isEmpty) return [];
    final batch = _db.batch();
    final ids = <String>[];
    for (final listing in listings) {
      final docRef = _db.collection('listings').doc();
      ids.add(docRef.id);
      batch.set(docRef, listing.toMap());
    }
    await batch.commit();
    return ids;
  }

  Future<void> updateListing(Listing listing) {
    final data = listing.toMap()..remove('createdAt');
    return _db.collection('listings').doc(listing.id).update(data);
  }

  Future<void> closeListing(String listingId) {
    return _db.collection('listings').doc(listingId).update({
      'status': 'closed',
    });
  }

  Future<void> reactivateListing(String listingId) {
    return _db.collection('listings').doc(listingId).update({
      'status': 'active',
    });
  }

  Future<Listing?> getListing(String listingId) async {
    try {
      final doc = await _db.collection('listings').doc(listingId).get();
      if (!doc.exists) return null;
      return Listing.fromDoc(doc);
    } catch (e) {
      debugPrint('Firestore getListing error: $e');
      return null;
    }
  }

  /// Fetches paginated active listings with cursor support
  ///
  /// [limit] - Number of listings to fetch (default: 20)
  /// [startAfter] - Document snapshot cursor for pagination
  /// [category] - Optional category filter
  /// [searchQuery] - Optional search query (client-side filtering)
  Future<PaginatedListingsResult> getPaginatedListings({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? category,
    String? searchQuery,
    String? city,
    String? region,
    int? minSalaryTl,
    int? maxSalaryTl,
    ListingDateFilter dateFilter = ListingDateFilter.all,
    EmploymentType? employmentType,
    ListingSortOrder sortOrder = ListingSortOrder.newest,
    String? season,
  }) async {
    try {
      Query query = _db.collection('listings');

      // Filter by active status
      query = query.where('status', isEqualTo: 'active');

      if (season != null && season.isNotEmpty) {
        query = query.where('season', isEqualTo: season);
      }

      final cutoff = dateFilter.cutoff;
      if (cutoff != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff),
        );
      }

      // Only (status, createdAt) is filtered/sorted server-side, which needs a
      // single Firestore composite index. category/city/employmentType and
      // salary-based sorting are applied client-side below instead of adding
      // a `.where()`/`.orderBy()` per combination - each such combination
      // would require its own composite index, and a missing one fails the
      // whole query (silently, from the UI's point of view) until someone
      // notices and creates it in the Firebase console.
      query = query.orderBy('createdAt', descending: true);

      // Apply cursor for pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      // Fetch one extra to determine if there are more results
      query = query.limit(limit + 1);

      final snapshot = await query.get();

      final pageDocs = snapshot.docs.take(limit).toList();
      var listings = pageDocs.map(Listing.fromDoc).toList();

      listings.sort((a, b) {
        final aBoosted =
            a.isBoosted && (a.boostExpiresAt?.isAfter(DateTime.now()) ?? false);
        final bBoosted =
            b.isBoosted && (b.boostExpiresAt?.isAfter(DateTime.now()) ?? false);
        if (aBoosted && !bBoosted) return -1;
        if (!aBoosted && bBoosted) return 1;
        return 0;
      });

      if (category != null && category.isNotEmpty) {
        listings = listings.where((l) => l.category == category).toList();
      }

      if (city != null && city.isNotEmpty) {
        listings = listings.where((l) => l.city == city).toList();
      }

      if (region != null && region.isNotEmpty) {
        listings = listings.where((l) => l.region == region).toList();
      }

      if (employmentType != null) {
        listings = listings
            .where((l) => l.employmentType == employmentType)
            .toList();
      }

      // Apply search query filter client-side if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        listings = listings
            .where(
              (l) =>
                  l.title.toLowerCase().contains(q) ||
                  l.location.toLowerCase().contains(q) ||
                  l.description.toLowerCase().contains(q),
            )
            .toList();
      }

      if (minSalaryTl != null) {
        listings = listings
            .where(
              (listing) =>
                  listing.maxSalaryTl != null &&
                  listing.maxSalaryTl! >= minSalaryTl,
            )
            .toList();
      }

      if (maxSalaryTl != null) {
        listings = listings
            .where(
              (listing) =>
                  listing.minSalaryTl != null &&
                  listing.minSalaryTl! <= maxSalaryTl,
            )
            .toList();
      }

      if (sortOrder != ListingSortOrder.newest) {
        listings.sort((a, b) {
          final aSalary = a.maxSalaryTl ?? a.minSalaryTl ?? 0;
          final bSalary = b.maxSalaryTl ?? b.minSalaryTl ?? 0;
          return sortOrder == ListingSortOrder.salaryHighToLow
              ? bSalary.compareTo(aSalary)
              : aSalary.compareTo(bSalary);
        });
      }

      // Check if there are more results
      final hasMore = snapshot.docs.length > limit;

      // Get last document for next cursor
      DocumentSnapshot? lastDoc;
      if (pageDocs.isNotEmpty) {
        lastDoc = pageDocs.last;
      }

      return PaginatedListingsResult(
        listings: listings,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      debugPrint('Firestore getPaginatedListings error: $e');
      return PaginatedListingsResult(
        listings: [],
        lastDocument: null,
        hasMore: false,
      );
    }
  }

  /// Fetches the next page of listings using the provided cursor
  ///
  /// [lastDocument] - Document snapshot cursor from previous page
  /// [limit] - Number of listings to fetch (default: 20)
  /// [category] - Optional category filter
  /// [searchQuery] - Optional search query (client-side filtering)
  Future<PaginatedListingsResult> getNextPage({
    required DocumentSnapshot lastDocument,
    int limit = 20,
    String? category,
    String? searchQuery,
    String? city,
    String? region,
    int? minSalaryTl,
    int? maxSalaryTl,
    ListingDateFilter dateFilter = ListingDateFilter.all,
    EmploymentType? employmentType,
    ListingSortOrder sortOrder = ListingSortOrder.newest,
    String? season,
  }) async {
    return getPaginatedListings(
      limit: limit,
      startAfter: lastDocument,
      category: category,
      searchQuery: searchQuery,
      city: city,
      region: region,
      minSalaryTl: minSalaryTl,
      maxSalaryTl: maxSalaryTl,
      dateFilter: dateFilter,
      employmentType: employmentType,
      sortOrder: sortOrder,
      season: season,
    );
  }
}

/// Result object for paginated listings queries
class PaginatedListingsResult {
  final List<Listing> listings;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedListingsResult({
    required this.listings,
    required this.lastDocument,
    required this.hasMore,
  });
}

final listingServiceProvider = Provider<ListingService>(
  (ref) => ListingService(FirebaseFirestore.instance),
);
