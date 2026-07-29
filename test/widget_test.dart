import 'package:flutter_test/flutter_test.dart';

import 'package:otelcim/app/theme.dart';

void main() {
  testWidgets('OtelcimTheme has blue primary color', (WidgetTester tester) async {
    expect(otelcimTheme.colorScheme.primary, otelcimBlue);
  });
}
