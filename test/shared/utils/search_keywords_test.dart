import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/shared/utils/search_keywords.dart';

void main() {
  group('normalizeForSearch', () {
    test('folds Turkish letters and handles dotted/dotless I', () {
      expect(normalizeForSearch('Ayşe ÇAĞLAR'), 'ayse caglar');
      expect(normalizeForSearch('İzmir'), 'izmir');
      expect(normalizeForSearch('IŞIK'), 'isik');
      expect(normalizeForSearch('Ürgüp Kapadokya'), 'urgup kapadokya');
    });
  });

  group('buildSearchKeywords', () {
    final keywords = buildSearchKeywords([
      'Ayşe Aday',
      'seeker@e2e.test',
      null,
      '',
      'Deniz Otel',
    ]);

    test('contains word prefixes from length 2', () {
      expect(keywords, containsAll(['ay', 'ays', 'ayse', 'ad', 'aday', 'de', 'deniz', 'otel']));
      expect(keywords, isNot(contains('a')));
    });

    test('contains the whole e-mail and its local part prefixes', () {
      expect(keywords, containsAll(['seeker@e2e.test', 'se', 'seeker']));
    });

    test('is sorted, unique and capped', () {
      expect(keywords, orderedEquals([...keywords]..sort()));
      expect(keywords.toSet().length, keywords.length);
      final long = buildSearchKeywords([List.filled(80, 'kelimeuzun').join(' '), 'a' * 200]);
      expect(long.length, lessThanOrEqualTo(150));
    });

    test('long words stop at the max prefix length', () {
      final k = buildSearchKeywords(['Misafirilişkileriuzmanı']);
      expect(k.every((w) => w.length <= maxPrefix), isTrue);
    });
  });

  group('searchToken / matchesAllWords', () {
    test('uses the longest word, normalized', () {
      expect(searchToken('ayşe  ad'), 'ayse');
      expect(searchToken('  '), isNull);
      expect(searchToken('a'), isNull);
    });

    test('an e-mail is searched as a whole', () {
      expect(searchToken('Seeker@E2E.test'), 'seeker@e2e.test');
    });

    test('every query word must prefix-match a keyword', () {
      final k = buildSearchKeywords(['Resepsiyonist Aranıyor', 'Deniz Otel', 'Antalya']);
      expect(matchesAllWords(k, 'resep antal'), isTrue);
      expect(matchesAllWords(k, 'resep izmir'), isFalse);
    });
  });
}
