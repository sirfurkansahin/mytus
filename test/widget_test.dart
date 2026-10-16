import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sayaç test ekranı hazır sayaçla açılır', (tester) async {
    await tester.pumpWidget(const MyTusApp());
    await tester.pumpAndSettle();

    expect(find.text('F.T. time'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Başlat'), findsOneWidget);

    // Ağaçı kaldır: bekleyen zamanlayıcı kalmasın.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Süre seçimi sayacı günceller', (tester) async {
    await tester.pumpWidget(const MyTusApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('5 dk'));
    await tester.pumpAndSettle();
    expect(find.text('05:00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
