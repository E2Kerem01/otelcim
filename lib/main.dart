import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'firebase_options.dart';
import 'shared/models/conversation.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/chat_service.dart';
import 'shared/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: OtelcimApp()));
}

class OtelcimApp extends ConsumerStatefulWidget {
  const OtelcimApp({super.key});

  @override
  ConsumerState<OtelcimApp> createState() => _OtelcimAppState();
}

class _OtelcimAppState extends ConsumerState<OtelcimApp> {
  StreamSubscription<List<Conversation>>? _conversationsSub;
  final Map<String, DateTime?> _lastUpdatedAt = {};
  String? _watchingUid;

  @override
  void initState() {
    super.initState();
    ref.read(notificationServiceProvider).init();
    ref.listenManual(authStateProvider, (previous, next) {
      final uid = next.value?.uid;
      if (uid == null) {
        _conversationsSub?.cancel();
        _conversationsSub = null;
        _watchingUid = null;
        _lastUpdatedAt.clear();
      } else if (_watchingUid != uid) {
        _watchConversationsFor(uid);
      }
    }, fireImmediately: true);
  }

  void _watchConversationsFor(String uid) {
    _conversationsSub?.cancel();
    _watchingUid = uid;
    _lastUpdatedAt.clear();
    _conversationsSub = ref.read(chatServiceProvider).watchConversations(uid).listen((conversations) {
      for (final conversation in conversations) {
        final previousUpdatedAt = _lastUpdatedAt[conversation.id];
        final isNewMessage = previousUpdatedAt != null &&
            conversation.updatedAt != null &&
            conversation.updatedAt!.isAfter(previousUpdatedAt);
        _lastUpdatedAt[conversation.id] = conversation.updatedAt;

        final isViewingThisChat = ref.read(currentChatIdProvider) == conversation.id;
        if (isNewMessage && conversation.lastSenderId != uid && !isViewingThisChat) {
          ref.read(notificationServiceProvider).showMessageNotification(
                id: conversation.id.hashCode,
                title: 'Yeni mesaj',
                body: conversation.lastMessage,
              );
        }
      }
    });
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Otelcim',
      debugShowCheckedModeBanner: false,
      theme: otelcimTheme,
      routerConfig: router,
    );
  }
}
