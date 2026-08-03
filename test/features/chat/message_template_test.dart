import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/chat/domain/message_template.dart';

void main() {
  test('exposes at least 4 templates', () {
    expect(messageTemplates.length, greaterThanOrEqualTo(4));
  });

  test('every template builds non-empty text containing the listing title', () {
    for (final template in messageTemplates) {
      final text = template.build('Resepsiyon Görevlisi');
      expect(text, isNotEmpty);
      expect(text, contains('Resepsiyon Görevlisi'));
      expect(template.title, isNotEmpty);
      expect(template.icon, isNotEmpty);
    }
  });
}
