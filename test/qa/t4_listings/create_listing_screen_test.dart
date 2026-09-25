import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/listings/presentation/create_listing_screen.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/providers/profile_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

UserProfile _profile({String userType = 'jobseeker', bool isAdmin = false}) {
  final now = DateTime(2026);
  return UserProfile(
    id: 'seeker',
    email: 'seeker@example.com',
    userType: userType,
    isAdmin: isAdmin,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('job seeker sees a guard instead of the create form', (tester) async {
    final auth = MockAuthService();
    const user = AppUser(uid: 'seeker', email: 'seeker@example.com');
    when(() => auth.currentUser).thenReturn(user);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => auth),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(_profile()),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('tr'), Locale('en')],
          home: CreateListingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('İlan vermek yalnızca işveren hesapları için kullanılabilir.'),
      findsOneWidget,
    );
    expect(find.text('İlanı Yayınla'), findsNothing);
  });
}
