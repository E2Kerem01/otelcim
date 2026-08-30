import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'firebase_options.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/locale_service.dart';
import 'shared/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Arka plan FCM mesajı alındı: ${message.messageId}');
}

// TEST-ONLY scaffolding, off by default. Never set in production builds.
// Points Auth/Firestore at the local emulator suite and optionally
// auto-signs-in a seeded test account, so live UI testing never touches
// production data or requires typing a password into the app.
const bool _kUseFirebaseEmulator = bool.fromEnvironment('E2E_USE_EMULATOR');
const String _kE2eTestEmail = String.fromEnvironment('E2E_TEST_EMAIL');
const String _kE2eTestPassword = String.fromEnvironment('E2E_TEST_PASSWORD');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (_kUseFirebaseEmulator) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    if (_kE2eTestEmail.isNotEmpty && _kE2eTestPassword.isNotEmpty) {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _kE2eTestEmail,
        password: _kE2eTestPassword,
      );
    }
  }
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await enforceRememberMePreference();
  runApp(const ProviderScope(child: OtelcimApp()));
}

class OtelcimApp extends ConsumerStatefulWidget {
  const OtelcimApp({super.key});

  @override
  ConsumerState<OtelcimApp> createState() => _OtelcimAppState();
}

class _OtelcimAppState extends ConsumerState<OtelcimApp> {
  @override
  void initState() {
    super.initState();
    final notificationService = ref.read(notificationServiceProvider);
    final router = ref.read(routerProvider);
    unawaited(
      notificationService.init(
        onOpenChat: (conversationId) => router.go('/chat/$conversationId'),
      ),
    );
    ref.listenManual(authStateProvider, (previous, next) {
      final uid = next.value?.uid;
      unawaited(notificationService.setCurrentUser(uid));
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      title: 'Otelcim',
      debugShowCheckedModeBanner: false,
      theme: otelcimTheme,
      themeMode: ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // The app still hardcodes most Turkish copy directly in widgets; only
      // the screens that go through AppLocalizations switch language today.
      // The locale is user-selectable (Hesabım > Uygulama Dili) and defaults
      // to Turkish; app_tr.arb is the template so any key not yet translated
      // in en/ru/de/ar falls back to Turkish rather than showing a key.
      // Migrating the remaining hardcoded strings to AppLocalizations is
      // tracked as follow-up work.
      locale: locale,
      routerConfig: router,
    );
  }
}
