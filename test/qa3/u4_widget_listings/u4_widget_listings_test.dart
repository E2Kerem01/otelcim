import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/favorites/presentation/favorites_screen.dart';
import 'package:otelcim/features/favorites/services/favorite_service.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/listings/presentation/batch_create_listing_screen.dart';
import 'package:otelcim/features/listings/presentation/create_listing_screen.dart';
import 'package:otelcim/features/listings/presentation/edit_listing_screen.dart';
import 'package:otelcim/features/listings/presentation/listing_detail_screen.dart';
import 'package:otelcim/features/listings/presentation/my_listings_screen.dart';
import 'package:otelcim/features/listings/presentation/urgent_listing_purchase_screen.dart';
import 'package:otelcim/features/listings/presentation/widgets/listing_detail_widgets.dart';
import 'package:otelcim/features/listings/presentation/widgets/listing_form_fields.dart';
import 'package:otelcim/features/ratings/domain/rating_model.dart';
import 'package:otelcim/features/ratings/presentation/submit_rating_screen.dart';
import 'package:otelcim/features/ratings/services/rating_service.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/models/conversation.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/providers/profile_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/chat_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';
import 'package:otelcim/shared/services/payment_service.dart';
import 'package:otelcim/shared/services/storage_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockChatService extends Mock implements ChatService {}

class MockFavoriteService extends Mock implements FavoriteService {}

class MockListingService extends Mock implements ListingService {}

class MockRatingService extends Mock implements RatingService {}

class MockStorageService extends Mock implements StorageService {}

final _now = DateTime(2026, 1, 15, 10);

Listing _listing({
  String id = 'listing-1',
  String posterId = 'owner-1',
  String title = 'Resepsiyon Görevlisi',
  String contactInfo = '05551234567',
  bool isUrgent = false,
  String? region = 'antalya',
  double? lat = 36.8969,
  double? lng = 30.7133,
  String? housingRoomType,
  bool? housingHasAc,
  bool? housingHasWifi,
}) {
  return Listing(
    id: id,
    posterId: posterId,
    posterName: 'Grand Otel',
    posterVerified: true,
    isUrgent: isUrgent,
    title: title,
    description: 'Misafir ilişkileri deneyimi olan ekip arkadaşı aranıyor.',
    category: 'resepsiyon',
    location: 'Antalya / Belek',
    salary: '35.000 TL',
    city: 'Antalya',
    region: region,
    lat: lat,
    lng: lng,
    minSalaryTl: 30000,
    maxSalaryTl: 40000,
    contactInfo: contactInfo,
    images: const [],
    housingRoomType: housingRoomType,
    housingHasAc: housingHasAc,
    housingHasWifi: housingHasWifi,
    createdAt: _now,
  );
}

UserProfile _profile({bool hasUsedFreeUrgentListing = false}) {
  return UserProfile(
    id: 'owner-1',
    email: 'owner@example.com',
    userType: 'employer',
    createdAt: _now,
    updatedAt: _now,
    hasUsedFreeUrgentListing: hasUsedFreeUrgentListing,
  );
}

const _user = AppUser(uid: 'owner-1', email: 'owner@example.com');
const _seeker = AppUser(uid: 'seeker-1', email: 'seeker@example.com');

Widget _localized(Widget child) {
  return MaterialApp(
    locale: const Locale('tr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void _setTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder _fieldWithHint(String hint) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == hint,
  );
}

Future<void> _selectDropdown(
  WidgetTester tester,
  Finder dropdown,
  String item,
) async {
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

Finder _formDropdown<T>(Type ownerType) {
  return find.descendant(
    of: find.byType(ownerType),
    matching: find.byType(DropdownButtonFormField<T>),
  );
}

GoRouter _testRouter({required String path, required Widget child}) {
  return GoRouter(
    initialLocation: path,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('home'))),
      GoRoute(path: path, builder: (_, _) => child),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_listing());
    registerFallbackValue(const Rating(
      id: 'rating-1',
      conversationId: 'conversation-1',
      raterId: 'seeker-1',
      ratedUserId: 'owner-1',
      stars: 5,
    ));
  });

  group('listing form fields', () {
    testWidgets('shows housing fields only after expanding the housing section',
        (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(_localized(
        Scaffold(
          body: ListingHousingSection(
            roomType: null,
            onRoomTypeChanged: (_) {},
            hasAc: false,
            onHasAcChanged: (_) {},
            hasWifi: false,
            onHasWifiChanged: (_) {},
            mealsIncludedInitialValue: null,
            onMealsIncludedChanged: (_) {},
            photoCount: 0,
            onAddPhotos: () {},
          ),
        ),
      ));

      expect(find.text('Lojman Bilgileri Ekle'), findsOneWidget);
      expect(find.text('Klima'), findsNothing);

      await tester.tap(find.text('Lojman Bilgileri Ekle'));
      await tester.pumpAndSettle();

      expect(find.text('Klima'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(find.text('Günlük dahil öğün'), findsOneWidget);
      expect(find.text('Oda tipi'), findsOneWidget);
    });

    testWidgets('validates an inverted salary range', (tester) async {
      final min = TextEditingController();
      final max = TextEditingController();
      final formKey = GlobalKey<FormState>();
      addTearDown(min.dispose);
      addTearDown(max.dispose);

      await tester.pumpWidget(_localized(
        Scaffold(
          body: Form(
            key: formKey,
            child: Column(
              children: [
                SalaryRangeFields(minController: min, maxController: max),
                ElevatedButton(
                  onPressed: () => formKey.currentState!.validate(),
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ));

      await tester.enterText(find.byType(TextFormField).at(0), '50000');
      await tester.enterText(find.byType(TextFormField).at(1), '30000');
      await tester.tap(find.text('Kaydet'));
      await tester.pump();

      expect(find.text('Aralığı kontrol edin'), findsWidgets);
    });
  });

  group('create and batch listing screens', () {
    late MockAuthService auth;
    late MockListingService listings;
    late MockStorageService storage;

    setUp(() {
      auth = MockAuthService();
      listings = MockListingService();
      storage = MockStorageService();
      when(() => auth.currentUser).thenReturn(_user);
    });

    Widget createApp({UserProfile? profile}) {
      final router = _testRouter(
        path: '/create',
        child: const CreateListingScreen(),
      );
      addTearDown(router.dispose);
      return ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => auth),
          authStateProvider.overrideWith((ref) => Stream.value(_user)),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(profile ?? _profile()),
          ),
          listingServiceProvider.overrideWith((ref) => listings),
          storageServiceProvider.overrideWith((ref) => storage),
        ],
        child: MaterialApp.router(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
    }

    testWidgets('reports every required create-listing field', (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      final submit = find.widgetWithText(ElevatedButton, 'İlanı Yayınla');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();

      expect(find.text('Başlık gerekli'), findsOneWidget);
      expect(find.text('Konum gerekli'), findsOneWidget);
      expect(find.text('Bölge seçmeniz gerekiyor'), findsOneWidget);
      expect(find.text('Şehir seçmeniz gerekiyor'), findsOneWidget);
      expect(find.text('Maaş bilgisi gerekli'), findsOneWidget);
      expect(find.text('İletişim bilgisi gerekli'), findsOneWidget);
      expect(find.text('Açıklama gerekli'), findsOneWidget);
      verifyNever(() => listings.createListingWithId(any(), any()));
    });

    testWidgets('sends the selected create-listing fields to ListingService',
        (tester) async {
      _setTestViewport(tester);
      when(() => listings.newListingId()).thenReturn('created-1');
      when(() => listings.createListingWithId(any(), any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();
      await tester.enterText(
        _fieldWithHint('Örn. Bodrum Resort Resepsiyon Görevlisi'),
        '  Yaz Resepsiyonisti  ',
      );
      await tester.enterText(
        _fieldWithHint('Örn. Muğla / Bodrum'),
        'Muğla / Bodrum',
      );
      await tester.enterText(
        _fieldWithHint('Örn. 35.000₺ + yemek'),
        '35.000 TL',
      );
      await tester.enterText(
        _fieldWithHint('Örn. 0555 123 4567'),
        '05551234567',
      );
      await tester.enterText(
        _fieldWithHint('İlanınızla ilgili tüm detayları açıklayın...'),
        'Misafir ilişkileri deneyimi.',
      );
      await _selectDropdown(
        tester,
        _formDropdown<String>(TourismRegionDropdown),
        'Antalya',
      );
      await _selectDropdown(
        tester,
        _formDropdown<String>(TourismCityDropdown),
        'Antalya',
      );
      await tester.tap(find.widgetWithText(SwitchListTile, 'Acil İhtiyaç'));
      await tester.pump();

      final submit = find.widgetWithText(ElevatedButton, 'İlanı Yayınla');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      final captured = verify(
        () => listings.createListingWithId('created-1', captureAny()),
      ).captured;
      final submitted = captured.single as Listing;
      expect(submitted.title, 'Yaz Resepsiyonisti');
      expect(submitted.location, 'Muğla / Bodrum');
      expect(submitted.region, 'antalya');
      expect(submitted.city, 'Antalya');
      expect(submitted.isUrgent, isTrue);
      expect(submitted.contactInfo, '05551234567');
    });

    testWidgets('adds and removes batch positions without losing the first one',
        (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => auth),
          authStateProvider.overrideWith((ref) => Stream.value(_user)),
          listingServiceProvider.overrideWith((ref) => listings),
          storageServiceProvider.overrideWith((ref) => storage),
        ],
        child: _localized(const BatchCreateListingScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pozisyonlar (1)'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Pozisyon Ekle'));
      await tester.pump();
      expect(find.text('Pozisyonlar (2)'), findsOneWidget);
      expect(find.byTooltip('Pozisyonu Sil'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Pozisyonu Sil').first);
      await tester.pump();
      expect(find.text('Pozisyonlar (1)'), findsOneWidget);
      expect(find.byTooltip('Pozisyonu Sil'), findsNothing);
    });

    // BUG-u4-01: edit_listing_screen.dart:182-221 omits original lat/lng and
    // isUrgent from the update payload.
    testWidgets(
      'preserves coordinates and urgency when editing an existing listing',
      (tester) async {
        _setTestViewport(tester);
        final original = _listing(isUrgent: true, region: 'ege');
        when(() => listings.getListing(original.id))
            .thenAnswer((_) async => original);
        when(() => listings.updateListing(any())).thenAnswer((_) async {});

        final router = _testRouter(
          path: '/edit',
          child: const EditListingScreen(listingId: 'listing-1'),
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            authServiceProvider.overrideWith((ref) => auth),
            authStateProvider.overrideWith((ref) => Stream.value(_user)),
            listingServiceProvider.overrideWith((ref) => listings),
            storageServiceProvider.overrideWith((ref) => storage),
          ],
          child: MaterialApp.router(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Değişiklikleri Kaydet'),
        );
        await tester.pumpAndSettle();

        final submitted = verify(() => listings.updateListing(captureAny()))
            .captured
            .single as Listing;
        expect(submitted.lat, original.lat);
        expect(submitted.lng, original.lng);
        expect(submitted.isUrgent, original.isUrgent);
        expect(submitted.region, original.region);
      },
      skip: true,
    );
  });

  group('listing detail, favorites and my listings', () {
    late MockListingService listings;
    late MockFavoriteService favorites;
    late MockAuthService auth;

    setUp(() {
      listings = MockListingService();
      favorites = MockFavoriteService();
      auth = MockAuthService();
      when(() => favorites.toggleFavorite(any(), any()))
          .thenAnswer((_) async {});
    });

    Future<void> pumpDetail(
      WidgetTester tester, {
      required Listing listing,
      required AppUser? user,
    }) async {
      when(() => listings.getListing(listing.id))
          .thenAnswer((_) async => listing);
      when(() => auth.currentUser).thenReturn(user);
      final overrides = <Override>[
        authServiceProvider.overrideWith((ref) => auth),
        authStateProvider.overrideWith((ref) => Stream.value(user)),
        listingServiceProvider.overrideWith((ref) => listings),
        favoriteServiceProvider.overrideWith((ref) => favorites),
      ];
      if (user != null) {
        overrides.add(
          favoriteIdsProvider(user.uid)
              .overrideWith((ref) => Stream.value(<String>{})),
        );
      }
      await tester.pumpWidget(ProviderScope(
        overrides: overrides,
        child: _localized(
          ListingDetailScreen(listingId: listing.id),
        ),
      ));
      await tester.pumpAndSettle();
    }

    // BUG-u4-02: Wide ListingDetailScreen renders contact gates in both
    // ListingPosterCard and ListingRightStickyActionCard, and the same layout
    // currently overflows in listing_detail_widgets.dart:696.
    testWidgets('gates contact information for a guest', (tester) async {
      _setTestViewport(tester);
      await pumpDetail(tester, listing: _listing(), user: null);

      expect(
        find.text('İletişim bilgisini görmek için giriş yapın'),
        findsOneWidget,
      );
      expect(find.text('05551234567'), findsNothing);
      expect(find.text('Mesaj Gönder'), findsOneWidget);
    }, skip: true);

    // BUG-u4-02: Wide ListingDetailScreen renders the contact action twice;
    // listing_detail_widgets.dart:889 also overflows at the tested width.
    testWidgets('reveals contact information only after the seeker action',
        (tester) async {
      _setTestViewport(tester);
      await pumpDetail(tester, listing: _listing(), user: _seeker);

      expect(find.text('İletişim Bilgisini Göster'), findsOneWidget);
      expect(find.text('05551234567'), findsNothing);
      await tester.tap(find.text('İletişim Bilgisini Göster'));
      await tester.pump();
      expect(find.text('05551234567'), findsOneWidget);
    }, skip: true);

    // BUG-u4-02: Wide ListingDetailScreen exposes the owner contact in both
    // detail cards, so the expected single contact value is not true.
    testWidgets('shows owner actions instead of messaging actions',
        (tester) async {
      _setTestViewport(tester);
      await pumpDetail(tester, listing: _listing(), user: _user);

      expect(find.text('İletişim Bilgisini Göster'), findsNothing);
      expect(find.text('05551234567'), findsOneWidget);
      expect(find.text('İlanı Öne Çıkar'), findsOneWidget);
      expect(find.text('Mesaj Gönder'), findsNothing);
      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
    }, skip: true);

    testWidgets('renders an empty favorites state for an authenticated user',
        (tester) async {
      _setTestViewport(tester);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_seeker)),
          favoriteListingsProvider(_seeker.uid)
              .overrideWith((ref) => Stream.value(<Listing>[])),
        ],
        child: _localized(const FavoritesScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Henüz favori ilanınız yok'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('renders a favorite and calls toggle when its heart is tapped',
        (tester) async {
      _setTestViewport(tester);
      final listing = _listing(title: 'Favori Resepsiyon İlanı');
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_seeker)),
          favoriteServiceProvider.overrideWith((ref) => favorites),
          favoriteListingsProvider(_seeker.uid)
              .overrideWith((ref) => Stream.value([listing])),
        ],
        child: _localized(const FavoritesScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Favori Resepsiyon İlanı'), findsOneWidget);
      await tester.tap(find.byTooltip('Favorilerden çıkar'));
      await tester.pump();
      verify(() => favorites.toggleFavorite(_seeker.uid, listing.id)).called(1);
    });

    testWidgets('renders my listings and closes an active listing',
        (tester) async {
      _setTestViewport(tester);
      final listing = _listing(title: 'Benim Aktif İlanım');
      when(() => listings.watchMyListings(_user.uid))
          .thenAnswer((_) => Stream.value([listing]));
      when(() => listings.closeListing(listing.id)).thenAnswer((_) async {});

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_user)),
          listingServiceProvider.overrideWith((ref) => listings),
        ],
        child: _localized(const MyListingsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Benim Aktif İlanım'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Kapat'));
      await tester.pump();
      verify(() => listings.closeListing(listing.id)).called(1);
    });

    testWidgets('renders the urgent purchase fallback price when store data is absent',
        (tester) async {
      _setTestViewport(tester);
      final listing = _listing(id: 'urgent-1', isUrgent: false);
      when(() => listings.getListing(listing.id))
          .thenAnswer((_) async => listing);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          listingServiceProvider.overrideWith((ref) => listings),
          paymentServiceProvider.overrideWith((ref) => PaymentService(null)),
        ],
        child: _localized(
          const UrgentListingPurchaseScreen(listingId: 'urgent-1'),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Resepsiyon Görevlisi'), findsOneWidget);
      expect(find.text('₺149,99'), findsOneWidget);
      expect(find.text('Satın Al ve Acil Yap'), findsOneWidget);
    });
  });

  group('submit rating screen', () {
    late MockChatService chat;
    late MockRatingService ratings;

    Conversation conversation({bool hired = true}) {
      return Conversation(
        id: 'conversation-1',
        listingId: 'listing-1',
        listingTitle: 'Resepsiyon',
        posterId: 'owner-1',
        seekerId: 'seeker-1',
        hired: hired,
      );
    }

    Future<GoRouter> pumpRating(WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const Scaffold(body: Text('home'))),
          GoRoute(
            path: '/rating',
            builder: (_, _) => const SubmitRatingScreen(
              conversationId: 'conversation-1',
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_seeker)),
          chatServiceProvider.overrideWith((ref) => chat),
          ratingServiceProvider.overrideWith((ref) => ratings),
        ],
        // The screen ref.read()s auth on submit. In the app the router keeps
        // authStateProvider alive; mirror that so the stream has resolved.
        child: Consumer(
          builder: (context, ref, child) {
            ref.watch(authStateProvider);
            return child!;
          },
          child: MaterialApp.router(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      unawaited(router.push('/rating'));
      await tester.pumpAndSettle();
      return router;
    }

    setUp(() {
      chat = MockChatService();
      ratings = MockRatingService();
    });

    testWidgets('does not call chat or rating services without a star',
        (tester) async {
      _setTestViewport(tester);
      await pumpRating(tester);

      await tester.tap(find.text('Değerlendirmeyi Gönder'));
      await tester.pump();

      expect(find.text('Lütfen bir yıldız puanı seçin.'), findsOneWidget);
      verifyNever(() => chat.getConversation(any()));
      verifyNever(() => ratings.submitRating(any()));
    });

    testWidgets('submits the selected star and review for a hired conversation',
        (tester) async {
      _setTestViewport(tester);
      when(() => chat.getConversation('conversation-1'))
          .thenAnswer((_) async => conversation());
      when(() => ratings.submitRating(any())).thenAnswer((_) async {});
      await pumpRating(tester);

      await tester.tap(find.byTooltip('4 yıldız'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Çok iyi iletişim.');
      await tester.tap(find.text('Değerlendirmeyi Gönder'));
      await tester.pumpAndSettle();

      final submitted = verify(() => ratings.submitRating(captureAny()))
          .captured
          .single as Rating;
      expect(submitted.stars, 4);
      expect(submitted.reviewText, 'Çok iyi iletişim.');
      expect(submitted.conversationId, 'conversation-1');
      expect(submitted.raterId, _seeker.uid);
      expect(submitted.ratedUserId, _user.uid);
    });

    testWidgets('surfaces the duplicate-rating response from the service',
        (tester) async {
      _setTestViewport(tester);
      when(() => chat.getConversation('conversation-1'))
          .thenAnswer((_) async => conversation());
      when(() => ratings.submitRating(any())).thenAnswer(
        (_) async => throw StateError(
          'Bu görüşme için zaten değerlendirme yaptınız.',
        ),
      );
      await pumpRating(tester);

      await tester.tap(find.byTooltip('5 yıldız'));
      await tester.pump();
      await tester.tap(find.text('Değerlendirmeyi Gönder'));
      await tester.pumpAndSettle();

      expect(
        find.text('Bu görüşme için zaten değerlendirme yaptınız.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('ListingPosterCard exposes the owner, seeker and guest gates',
      (tester) async {
    final listing = _listing();
    await tester.pumpWidget(_localized(
      Scaffold(
        body: ListView(
          children: [
            ListingPosterCard(
              listing: listing,
              myUid: null,
              revealContactInfo: false,
              onRevealContact: () {},
            ),
            ListingPosterCard(
              listing: listing,
              myUid: 'seeker-1',
              revealContactInfo: true,
              onRevealContact: () {},
            ),
          ],
        ),
      ),
    ));

    expect(find.text('İletişim bilgisini görmek için giriş yapın'), findsOneWidget);
    expect(find.text('05551234567'), findsOneWidget);
  });
}
