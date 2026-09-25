import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/ads/presentation/admin_banner_ads_screen.dart';
import 'package:otelcim/features/ads/services/banner_ad_service.dart';

import 't3_helpers.dart';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  Future<void> seed(String id, Map<String, dynamic> extra) {
    return db.collection('banner_ads').doc(id).set({
      'title': 'Yaz Fırsatları',
      'advertiserName': 'Jolly Tur',
      'imageUrl': '',
      'targetUrl': 'https://www.jollytur.com',
      'order': 0,
      'isActive': true,
      'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      ...extra,
    });
  }

  Future<Map<String, dynamic>?> read(String id) async => (await db.collection('banner_ads').doc(id).get()).data();

  Future<void> pumpScreen(WidgetTester tester) async {
    useTallViewport(tester);
    // Below AdminPagedView.tableBreakpoint so the list renders as cards.
    tester.view.physicalSize = const Size(800, 2400);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bannerAdServiceProvider.overrideWithValue(BannerAdService(db))],
        child: const MaterialApp(home: AdminBannerAdsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openEditSheet(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Düzenle'));
    await tester.pumpAndSettle();
    expect(find.text('Banner Düzenle'), findsOneWidget);
  }

  Future<void> saveEdit(WidgetTester tester) async {
    await tester.tap(find.text('Değişiklikleri Kaydet'));
    await tester.pumpAndSettle();
  }

  group('AdminBannerAdsScreen — list', () {
    testWidgets('no banners: empty state, the "new banner" action stays available', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Bu filtreyle banner bulunamadı.'), findsOneWidget);
      expect(find.text('Yeni Banner'), findsOneWidget);
    });

    testWidgets('card shows sponsor, order and "Süresiz" / end date; inactive banners are listed too',
        (tester) async {
      await seed('a', {'order': 2, 'advertiserName': '', 'title': 'Süresiz Banner'});
      await seed('b', {
        'order': 3,
        'isActive': false,
        'title': 'Biten Banner',
        'endDate': Timestamp.fromDate(DateTime(2026, 10, 1)),
      });
      await pumpScreen(tester);
      // The default tab lists active banners only.
      expect(find.text('Biten Banner'), findsNothing);
      await tester.tap(find.text('Tümü'));
      await tester.pumpAndSettle();

      expect(find.text('Süresiz Banner'), findsOneWidget);
      expect(find.text('Sponsor: -'), findsOneWidget);
      expect(find.text('Sıra: 2'), findsOneWidget);
      expect(find.text('Süresiz'), findsOneWidget);
      expect(find.text('Biten Banner'), findsOneWidget);
      expect(find.text('Bitiş: 1.10.2026'), findsOneWidget);
    });

    testWidgets('active switch writes isActive=false to Firestore', (tester) async {
      await seed('a', {});
      await pumpScreen(tester);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect((await read('a'))!['isActive'], isFalse);
      // It leaves the "Aktif" tab and shows up under "Pasif".
      expect(find.text('Yaz Fırsatları'), findsNothing);
      await tester.tap(find.text('Pasif'));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });

    testWidgets('delete: cancelling the dialog keeps the banner', (tester) async {
      await seed('a', {});
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Sil'));
      await tester.pumpAndSettle();
      expect(find.text('Banner silinsin mi?'), findsOneWidget);
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      expect(await read('a'), isNotNull);
    });

    testWidgets('delete: confirming removes the document and confirms with a snackbar', (tester) async {
      await seed('a', {});
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Sil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();

      expect(await read('a'), isNull);
      expect(find.text('Banner silindi.'), findsOneWidget);
      expect(find.text('Bu filtreyle banner bulunamadı.'), findsOneWidget);
    });
  });

  group('AdminBannerAdsScreen — create form', () {
    testWidgets('saving an empty form shows all required-field errors and writes nothing', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Yeni Banner'));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Banner'ı Kaydet"));
      await tester.pumpAndSettle();

      expect(find.text('Başlık gerekli'), findsOneWidget);
      expect(find.text('Reklamveren adı gerekli'), findsOneWidget);
      expect(find.text('Hedef URL gerekli'), findsOneWidget);
      expect((await db.collection('banner_ads').get()).docs, isEmpty);
    });

    testWidgets('whitespace-only fields are rejected like empty ones', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Yeni Banner'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Banner Başlığı *'), '   ');
      await tester.tap(find.text("Banner'ı Kaydet"));
      await tester.pumpAndSettle();

      expect(find.text('Başlık gerekli'), findsOneWidget);
    });

    testWidgets('valid text but no uploaded image: blocked with a message, nothing written', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Yeni Banner'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Banner Başlığı *'), 'Kış Kampanyası');
      await tester.enterText(find.widgetWithText(TextFormField, 'Reklamveren Firma Adı *'), 'ETS Tur');
      await tester.enterText(find.widgetWithText(TextFormField, 'Hedef Bağlantı (URL) *'), 'https://etstur.com');
      await tester.tap(find.text("Banner'ı Kaydet"));
      await tester.pumpAndSettle();

      // The message offers "veya URL girin" but the form has no image-URL
      // field: uploading through Storage is the only way to add a banner.
      expect(find.text('Lütfen bir banner görseli yükleyin veya URL girin.'), findsOneWidget);
      expect((await db.collection('banner_ads').get()).docs, isEmpty);
      expect(find.text('Yeni Banner Ekle'), findsOneWidget, reason: 'sheet stays open');
    });
  });

  group('AdminBannerAdsScreen — edit form', () {
    // Editing needs an existing imageUrl (the form refuses to save without
    // one); CachedNetworkImage fails to load it in tests and shows its
    // errorWidget, which is fine for these assertions.
    const image = 'https://cdn.example.com/banner.jpg';

    testWidgets('edit prefills the form and saves the changed title, keeping other fields', (tester) async {
      await seed('a', {'imageUrl': image, 'order': 4});
      await pumpScreen(tester);
      await openEditSheet(tester);

      expect(find.widgetWithText(TextFormField, 'Yaz Fırsatları'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Banner Başlığı *'), '  Sonbahar Fırsatları  ');
      await saveEdit(tester);

      final data = (await read('a'))!;
      expect(data['title'], 'Sonbahar Fırsatları', reason: 'input is trimmed');
      expect(data['order'], 4);
      expect(data['imageUrl'], image);
      expect((data['createdAt'] as Timestamp).toDate(), DateTime(2026, 9, 1));
      expect(find.text('Banner güncellendi.'), findsOneWidget);
      expect(find.text('Banner Düzenle'), findsNothing, reason: 'sheet closes');
    });

    testWidgets('[BUG-t3-17] end date before start date is rejected', (tester) async {
      await seed('a', {
        'imageUrl': image,
        'startDate': Timestamp.fromDate(DateTime(2026, 10, 10)),
        'endDate': Timestamp.fromDate(DateTime(2026, 10, 1)),
      });
      await pumpScreen(tester);
      // The default tab lists active banners only.
      expect(find.text('Biten Banner'), findsNothing);
      await tester.tap(find.text('Tümü'));
      await tester.pumpAndSettle();
      await openEditSheet(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Banner Başlığı *'), 'Değişti');
      await saveEdit(tester);

      // Expected: validation error; actual: saved, banner can never show.
      expect((await read('a'))!['title'], 'Yaz Fırsatları');
    }, skip: widgetBug('BUG-t3-17: form accepts endDate < startDate (banner is silently never shown)'));

    testWidgets('[BUG-t3-17] target URL without http(s) scheme is rejected', (tester) async {
      await seed('a', {'imageUrl': image});
      await pumpScreen(tester);
      await openEditSheet(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Hedef Bağlantı (URL) *'), 'www.jollytur.com');
      await saveEdit(tester);

      expect((await read('a'))!['targetUrl'], 'https://www.jollytur.com');
    }, skip: widgetBug('BUG-t3-17: "www.jollytur.com" is saved; launchUrl cannot open a scheme-less URI'));

    testWidgets('[BUG-t3-17] non-numeric order is rejected instead of silently becoming 0', (tester) async {
      await seed('a', {'imageUrl': image, 'order': 5});
      await pumpScreen(tester);
      await openEditSheet(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Sıralama Önceliği (0, 1, 2...)'), 'ilk');
      await saveEdit(tester);

      expect((await read('a'))!['order'], 5);
    }, skip: widgetBug('BUG-t3-17: int.tryParse(...) ?? 0 silently moves the banner to the front'));
  });
}
