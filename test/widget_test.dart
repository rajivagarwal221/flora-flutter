import 'package:flutter_test/flutter_test.dart';

import 'package:sidhi_florals/main.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const SidhiApp());
    await tester.pump();
    expect(find.byType(SidhiApp), findsOneWidget);
  });
}
