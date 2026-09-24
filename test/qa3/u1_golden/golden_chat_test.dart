import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:otelcim/features/chat/presentation/widgets/chat_detail_widgets.dart';
import 'package:otelcim/shared/models/message.dart';
import 'package:otelcim/shared/services/chat_service.dart';

import 'golden_test_helpers.dart';

class _MockChatService extends Mock implements ChatService {}

const _chatMessages = <String, String>{
  'short': 'Merhaba, ilan hâlâ güncel mi?',
  'long':
      'Merhaba, vardiya saatleri ve lojman koşulları hakkında bilgi paylaşabilir misiniz? Uygunsanız bu hafta kısa bir görüşme planlamak isterim.',
  'emoji': 'Merhaba 👋 Başvurumu gönderdim; görüşmek üzere! 😊',
};

Widget _chatApp(Locale locale, String text) {
  final mockChat = _MockChatService();
  when(() => mockChat.watchMessages('golden-conversation')).thenAnswer(
    (_) => Stream.value([
      Message(
        id: 'message-1',
        senderId: 'other-user',
        text: text,
        sentAt: DateTime(2026, 1, 2, 10, 30),
      ),
      Message(
        id: 'message-2',
        senderId: 'me',
        text: 'Teşekkürler, bugün içinde dönüş yapacağım.',
        sentAt: DateTime(2026, 1, 2, 10, 31),
      ),
    ]),
  );
  return ProviderScope(
    overrides: [
      chatServiceProvider.overrideWith((ref) => mockChat),
    ],
    child: localizedGoldenApp(
      locale: locale,
      home: const Scaffold(
        body: ChatMessageList(
          conversationId: 'golden-conversation',
          myUid: 'me',
        ),
      ),
    ),
  );
}

Widget _emptyChatApp(Locale locale) {
  final mockChat = _MockChatService();
  when(() => mockChat.watchMessages('golden-conversation'))
      .thenAnswer((_) => Stream.value([]));
  return ProviderScope(
    overrides: [
      chatServiceProvider.overrideWith((ref) => mockChat),
    ],
    child: localizedGoldenApp(
      locale: locale,
      home: const Scaffold(
        body: ChatMessageList(
          conversationId: 'golden-conversation',
          myUid: 'me',
        ),
      ),
    ),
  );
}

void main() {
  for (final locale in goldenLocales) {
    for (final entry in _chatMessages.entries) {
      testWidgets(
        'chat ${entry.key} ${goldenLocaleName(locale)}',
        (tester) async {
          configureGoldenViewport(tester);
          await tester.pumpWidget(_chatApp(locale, entry.value));
          await tester.pumpAndSettle();

          await expectLater(
            find.byType(ChatMessageList),
            matchesGoldenFile(
              'goldens/chat_${entry.key}_${goldenLocaleName(locale)}.png',
            ),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'chat empty ${goldenLocaleName(locale)}',
      (tester) async {
        configureGoldenViewport(tester);
        await tester.pumpWidget(_emptyChatApp(locale));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(ChatMessageList),
          matchesGoldenFile('goldens/chat_empty_${goldenLocaleName(locale)}.png'),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
