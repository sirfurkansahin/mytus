import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('Ana ekran acilir', (WidgetTester tester) async {
    await tester.pumpWidget(const MyTusApp());

    expect(find.text('Kurulum başarılı'), findsOneWidget);
  });
}
