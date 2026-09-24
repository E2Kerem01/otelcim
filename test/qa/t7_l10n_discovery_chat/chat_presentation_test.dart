import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/chat/domain/interview_slot_model.dart';
import 'package:otelcim/features/chat/domain/message_template.dart';
import 'package:otelcim/features/chat/presentation/chat_list_screen.dart';
import 'package:otelcim/features/chat/presentation/widgets/chat_detail_widgets.dart';
import 'package:otelcim/features/chat/presentation/widgets/message_template_sheet.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/models/conversation.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/providers/profile_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/chat_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockChatService extends Mock implements ChatService {}

void main() {
  group('Chat Presentation & Widgets Tests', () {
    testWidgets('ChatListScreen renders relative time formatting correctly for conversations', (tester) async {
      final mockAuth = MockAuthService();
      final mockChat = MockChatService();
      const testUser = AppUser(uid: 'my_user', email: 'me@hotel.com');
      final now = DateTime.now();

      final conversations = [
        Conversation(
          id: 'c1',
          listingId: 'l1',
          listingTitle: 'Job 1',
          posterId: 'my_user',
          seekerId: 'other_user',
          lastMessage: 'm1',
          updatedAt: now.subtract(const Duration(seconds: 30)),
        ),
        Conversation(
          id: 'c2',
          listingId: 'l2',
          listingTitle: 'Job 2',
          posterId: 'my_user',
          seekerId: 'other_user',
          lastMessage: 'm2',
          updatedAt: now.subtract(const Duration(minutes: 25)),
        ),
        Conversation(
          id: 'c3',
          listingId: 'l3',
          listingTitle: 'Job 3',
          posterId: 'my_user',
          seekerId: 'other_user',
          lastMessage: 'm3',
          updatedAt: now.subtract(const Duration(hours: 4)),
        ),
        Conversation(
          id: 'c4',
          listingId: 'l4',
          listingTitle: 'Job 4',
          posterId: 'my_user',
          seekerId: 'other_user',
          lastMessage: 'm4',
          updatedAt: now.subtract(const Duration(days: 3)),
        ),
      ];

      when(() => mockAuth.currentUser).thenReturn(testUser);
      when(() => mockChat.watchConversations('my_user'))
          .thenAnswer((_) => Stream.value(conversations));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWith((ref) => mockAuth),
            chatServiceProvider.overrideWithValue(mockChat),
            userProfileProvider('other_user')
                .overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ChatListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('şimdi'), findsOneWidget);
      expect(find.text('25dk'), findsOneWidget);
      expect(find.text('4sa'), findsOneWidget);
      expect(find.text('3g'), findsOneWidget);
    });

    testWidgets('ChatListScreen shows unauthenticated login banner when currentUser is null', (tester) async {
      final mockAuth = MockAuthService();
      when(() => mockAuth.currentUser).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWith((ref) => mockAuth),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ChatListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mesajlaşmak İçin Giriş Yapın'), findsOneWidget);
      expect(find.text('Giriş Yap / Kayıt Ol'), findsOneWidget);
    });

    testWidgets('ChatListScreen shows empty state when conversation list is empty', (tester) async {
      final mockAuth = MockAuthService();
      final mockChat = MockChatService();

      const testUser = AppUser(uid: 'user_123', email: 'test@hotel.com');
      when(() => mockAuth.currentUser).thenReturn(testUser);
      when(() => mockChat.watchConversations('user_123'))
          .thenAnswer((_) => Stream.value(<Conversation>[]));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWith((ref) => mockAuth),
            chatServiceProvider.overrideWithValue(mockChat),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ChatListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Henüz Mesajınız Yok'), findsOneWidget);
    });

    testWidgets('ChatListScreen renders conversation tiles and immediate availability badge', (tester) async {
      final mockAuth = MockAuthService();
      final mockChat = MockChatService();

      const testUser = AppUser(uid: 'my_user', email: 'me@hotel.com');
      final now = DateTime.now();

      final conversations = [
        Conversation(
          id: 'c1',
          listingId: 'l1',
          listingTitle: 'Resepsiyon Şefi',
          posterId: 'my_user',
          seekerId: 'other_user',
          lastMessage: 'Görüşmek isterim.',
          updatedAt: now.subtract(const Duration(minutes: 10)),
        ),
      ];

      final otherProfile = UserProfile(
        id: 'other_user',
        email: 'candidate@mail.com',
        userType: 'jobseeker',
        availableImmediately: true,
        createdAt: now,
        updatedAt: now,
      );

      when(() => mockAuth.currentUser).thenReturn(testUser);
      when(() => mockChat.watchConversations('my_user'))
          .thenAnswer((_) => Stream.value(conversations));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWith((ref) => mockAuth),
            chatServiceProvider.overrideWithValue(mockChat),
            userProfileProvider('other_user')
                .overrideWith((ref) => Stream.value(otherProfile)),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ChatListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resepsiyon Şefi'), findsOneWidget);
      expect(find.text('Görüşmek isterim.'), findsOneWidget);
      expect(find.text('10dk'), findsOneWidget);
      expect(find.text('Hemen Başlayabilir'), findsOneWidget);
    });

    testWidgets('ChatMessageComposer enters text and invokes onSend callback', (tester) async {
      final controller = TextEditingController();
      bool sent = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageComposer(
              controller: controller,
              onSend: () => sent = true,
            ),
          ),
        ),
      );

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Merhaba, ilan duruyor mu?');
      expect(controller.text, equals('Merhaba, ilan duruyor mu?'));

      final sendButton = find.byIcon(Icons.send_rounded);
      await tester.tap(sendButton);
      expect(sent, isTrue);
    });

    testWidgets('ChatHiredBanner renders success text and evaluation button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatHiredBanner(conversationId: 'conv_hired_1'),
          ),
        ),
      );

      expect(find.text('Bu görüşmede işe alım gerçekleşti.'), findsOneWidget);
      expect(find.text('Deneyimini Değerlendir'), findsOneWidget);
    });

    testWidgets('InterviewSlotBanner renders confirmed status banner', (tester) async {
      final mockChat = MockChatService();
      final now = DateTime.now().add(const Duration(days: 1));

      final confirmedSlot = InterviewSlot(
        id: 'slot_1',
        proposedBy: 'employer_1',
        slots: [now],
        selectedSlot: now,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      when(() => mockChat.watchInterviewSlots('conv_slot_test'))
          .thenAnswer((_) => Stream.value([confirmedSlot]));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatServiceProvider.overrideWithValue(mockChat),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: InterviewSlotBanner(
                conversationId: 'conv_slot_test',
                myUid: 'seeker_1',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mülakat Onaylandı'), findsOneWidget);
    });

    testWidgets('MessageTemplateSheet displays all 4 template options and builds text', (tester) async {
      String? selectedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedResult = await MessageTemplateSheet.show(
                    context,
                    listingTitle: 'Resepsiyonist',
                  );
                },
                child: const Text('Şablon Aç'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Şablon Aç'));
      await tester.pumpAndSettle();

      expect(find.text('İlk mesajını hazırlayalım'), findsOneWidget);
      expect(find.text('Kendimi Tanıtayım'), findsOneWidget);
      expect(find.text('Müsaitlik Bildireyim'), findsOneWidget);
      expect(find.text('Deneyimimi Özetleyeyim'), findsOneWidget);
      expect(find.text('Maaş Hakkında Soru Sorayım'), findsOneWidget);
      expect(find.text('Kendi mesajımı yazacağım'), findsOneWidget);

      // Tap first template
      await tester.tap(find.text('Kendimi Tanıtayım'));
      await tester.pumpAndSettle();

      expect(selectedResult, isNotNull);
      expect(selectedResult, contains('Resepsiyonist'));
      expect(selectedResult, contains('Bu alanda deneyimim var'));
    });

    test('MessageTemplate domain models format all 4 templates with listingTitle', () {
      expect(messageTemplates.length, equals(4));

      for (final template in messageTemplates) {
        final text = template.build('Aşçı');
        expect(text, contains('Aşçı'));
        expect(text.startsWith('Merhaba'), isTrue);
      }
    });
  });
}
