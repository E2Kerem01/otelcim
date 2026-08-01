import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/listings/domain/listing_model.dart';

class ListingService {
  ListingService(this._db);

  final FirebaseFirestore _db;

  Stream<List<Listing>> watchActiveListings({String? category, String? searchQuery}) {
    return _db.collection('listings').snapshots().map((snap) {
      var listings = snap.docs
          .map(Listing.fromDoc)
          .where((l) => l.status == ListingStatus.active)
          .toList();

      listings.sort((a, b) {
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
            .where((l) =>
                l.title.toLowerCase().contains(q) ||
                l.location.toLowerCase().contains(q) ||
                l.description.toLowerCase().contains(q))
            .toList();
      }

      return listings;
    }).handleError((error) {
      debugPrint('Firestore watchActiveListings warning: $error');
      return <Listing>[];
    });
  }

  Stream<List<Listing>> watchMyListings(String uid) {
    return _db.collection('listings').snapshots().map((snap) {
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
    }).handleError((error) {
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
          'description': 'Belek 5 Yıldızlı Otelimizde görevlendirilmek üzere diksiyonu düzgün, vardiyalı çalışabilecek resepsiyonist aranıyor. Lojman ve yemek mevcuttur.',
          'category': 'resepsiyon',
          'location': 'Antalya, Belek',
          'salary': '35.000 TL / Ay',
          'contactInfo': 'ik@belekluxuryresort.com - 0242 555 01 02',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'posterId': 'system_demo',
          'posterName': 'Grand Palace Bosphorus',
          'title': 'Chef de Partie / Aşçıbaşı Yardımcısı',
          'description': 'İstanbul Şişli lokasyonundaki otel mutfağımız için soğuk ve sıcak büfe tecrübeli aşçı ekibi aranmaktadır. SGK + Yemek + Prim.',
          'category': 'mutfak',
          'location': 'İstanbul, Şişli',
          'salary': '45.000 TL / Ay',
          'contactInfo': 'kariyer@grandpalace.com',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'posterId': 'system_demo',
          'posterName': 'Bodrum Sunset Beach Hotel',
          'title': 'Servis Elemanı & Garson (Sezonluk)',
          'description': 'Bodrum Yalıkavak otelimizde beach ve alakart restoranda çalışacak enerjik servis elemanları aranıyor. Lojman ve dolgun bahşiş imkanı.',
          'category': 'servis',
          'location': 'Muğla, Bodrum',
          'salary': '30.000 TL / Ay + Tip',
          'contactInfo': '0532 100 20 30',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'posterId': 'system_demo',
          'posterName': 'Cappadocia Cave Suites',
          'title': 'Kat Hizmetleri Görevlisi (Housekeeping)',
          'description': 'Nevşehir Ürgüp bölgesindeki butik otelimizde oda temizliği ve düzeninden sorumlu deneyimli kat görevlileri alınacaktır.',
          'category': 'kat_hizmetleri',
          'location': 'Nevşehir, Ürgüp',
          'salary': '28.000 TL / Ay',
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

  Future<void> updateListing(Listing listing) {
    return _db.collection('listings').doc(listing.id).update(listing.toMap());
  }

  Future<void> closeListing(String listingId) {
    return _db.collection('listings').doc(listingId).update({'status': 'closed'});
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
}

final listingServiceProvider = Provider<ListingService>((ref) => ListingService(FirebaseFirestore.instance));
