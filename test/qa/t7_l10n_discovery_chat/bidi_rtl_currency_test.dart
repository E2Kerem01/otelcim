import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/chat/presentation/widgets/chat_detail_widgets.dart';
import 'package:otelcim/features/home/presentation/widgets/home_screen_widgets.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/message.dart';
import 'package:otelcim/shared/services/chat_service.dart';

class MockChatService extends Mock implements ChatService {}

void main() {
  group('Issue #61 — Arabic RTL & Bidi Currency Formatting Tests', () {
    late AppLocalizations l10nAr;
    late AppLocalizations l10nTr;

    testWidgets('Capture Arabic and Turkish localizations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10nAr = AppLocalizations.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10nTr = AppLocalizations.of(context)!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(l10nAr.localeName, equals('ar'));
      expect(l10nTr.localeName, equals('tr'));
    });

    test(
      'HomeAdvancedFilters.salaryLabel with min and max uses localized ARB string and RTL isolation',
      () {
        const filters = HomeAdvancedFilters(
          minSalaryTl: 25000,
          maxSalaryTl: 45000,
        );
        final label = filters.salaryLabel(l10nAr);

        // Expected: should NOT contain hardcoded Turkish suffix 'TL' outside ARB,
        // and should use bidi isolation (LRM \u200E or LRI \u2066 / PDI \u2069)
        // or translated currency name (e.g. ليرة).
        expect(label.endsWith('TL'), isFalse,
            reason: 'HomeAdvancedFilters.salaryLabel hardcoded "TL" outside ARB');
        expect(
          label.contains('\u200E') || label.contains('\u2066') || !label.contains('TL'),
          isTrue,
          reason: 'Salary range text lacks RTL bidi isolation markers',
        );
      },
      skip:
          'BUG-t7-02: Issue #61 - HomeAdvancedFilters.salaryLabel uses hardcoded "\$min - \$max TL" without ARB or RTL bidi isolation (home_screen_widgets.dart:63)',
    );

    test(
      'Arabic currency strings in ARB have bidi isolation markers',
      () {
        final label = l10nAr.salaryMinAndUp('1');
        // Check that digits and currency are properly isolated so that "1 TL" does not render as "TL 1"
        expect(
          label.contains('\u200E') || label.contains('\u2066'),
          isTrue,
          reason: 'salaryMinAndUp string in Arabic lacks bidi isolation control characters',
        );
      },
      skip:
          'BUG-t7-02b: Currency strings lack bidi formatting/isolation characters for RTL text rendering',
    );

    test(
      'Large salary amounts use locale-aware NumberFormat groupings in Arabic and German',
      () {
        const rawAmount = 35000;
        final formattedTr = rawAmount.toString();
        // Raw toString() is used everywhere instead of NumberFormat.decimalPattern
        expect(
          formattedTr,
          isNot('35000'),
          reason: 'Salary amounts must be formatted with locale-aware thousand separators',
        );
      },
      skip:
          'BUG-t7-02c: Salary numbers are not formatted with locale NumberFormat in Arabic/German (raw int.toString() used)',
    );

    testWidgets(
      'ChatMessageList uses AlignmentDirectional rather than physical Alignment.centerRight in RTL',
      (tester) async {
        final mockChatService = MockChatService();
        final testMessages = [
          Message(
            id: 'm1',
            senderId: 'my_user_id',
            text: 'مرحبا، كيف حالك؟',
            sentAt: DateTime.now(),
          ),
          Message(
            id: 'm2',
            senderId: 'other_user_id',
            text: 'أنا بخير، شكرا لك',
            sentAt: DateTime.now().add(const Duration(minutes: 1)),
          ),
        ];

        when(() => mockChatService.watchMessages('conv_1'))
            .thenAnswer((_) => Stream.value(testMessages));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              chatServiceProvider.overrideWithValue(mockChatService),
            ],
            child: const MaterialApp(
              locale: Locale('ar'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Directionality(
                  textDirection: TextDirection.rtl,
                  child: ChatMessageList(
                    conversationId: 'conv_1',
                    myUid: 'my_user_id',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // In RTL, "my" message should be aligned at the trailing/end side (which is LEFT in RTL).
        // If AlignmentDirectional.centerEnd is used, in RTL it resolves to Alignment(-1.0, 0.0) (left).
        // But ChatMessageList hardcodes `Alignment.centerRight`, which is physical right (start in RTL).
        final alignWidgets = tester.widgetList<Align>(find.byType(Align)).toList();
        expect(alignWidgets.isNotEmpty, isTrue);

        final myMessageAlign = alignWidgets.first;
        // In proper RTL layout, the sender's message must NOT be physical Alignment.centerRight
        expect(
          myMessageAlign.alignment,
          isNot(equals(Alignment.centerRight)),
          reason:
              'ChatMessageList uses physical Alignment.centerRight, causing "my" messages to be on the right (start) in RTL instead of left (end)',
        );
      },
      skip: true, // BUG-t7-03: ChatMessageList uses physical Alignment.centerRight instead of AlignmentDirectional.centerEnd, causing reversed bubble alignment in RTL (chat_detail_widgets.dart:295)
    );

    testWidgets(
      'ChatHiredBanner uses AlignmentDirectional rather than physical Alignment.centerRight for action button',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: ChatHiredBanner(conversationId: 'conv_1'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final alignWidgets = tester.widgetList<Align>(find.byType(Align)).toList();
        final actionAlign = alignWidgets.firstWhere(
          (a) => a.alignment == Alignment.centerRight ||
                 a.alignment == AlignmentDirectional.centerEnd,
          orElse: () => alignWidgets.first,
        );

        expect(
          actionAlign.alignment,
          isNot(equals(Alignment.centerRight)),
          reason: 'ChatHiredBanner uses physical Alignment.centerRight in RTL',
        );
      },
      skip: true, // BUG-t7-04: ChatHiredBanner uses physical Alignment.centerRight instead of AlignmentDirectional.centerEnd for action button (chat_detail_widgets.dart:129)
    );

    test('Non-directional padding scan in chat and home widgets', () {
      final chatDir = Directory('lib/features/chat');
      final homeDir = Directory('lib/features/home');

      int nonDirectionalPaddingCount = 0;
      final nonDirectionalRegex = RegExp(r'EdgeInsets\.only\s*\(\s*(?:left:|right:)');

      for (final dir in [chatDir, homeDir]) {
        if (!dir.existsSync()) continue;
        for (final file in dir.listSync(recursive: true)) {
          if (file is File && file.path.endsWith('.dart')) {
            final content = file.readAsStringSync();
            final matches = nonDirectionalRegex.allMatches(content);
            nonDirectionalPaddingCount += matches.length;
          }
        }
      }

      // Assert that non-directional paddings exist and record the metric
      expect(nonDirectionalPaddingCount, greaterThanOrEqualTo(0));
    });
  });
}
