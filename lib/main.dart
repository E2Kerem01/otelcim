import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'firebase_options.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Arka plan FCM mesajı alındı: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
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
    unawaited(notificationService.init(
      onOpenChat: (conversationId) => router.go('/chat/$conversationId'),
    ));
    ref.listenManual(authStateProvider, (previous, next) {
      final uid = next.value?.uid;
      unawaited(notificationService.setCurrentUser(uid));
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Otelcim',
      debugShowCheckedModeBanner: false,
      theme: otelcimTheme,
      routerConfig: router,
    );
  }
}
