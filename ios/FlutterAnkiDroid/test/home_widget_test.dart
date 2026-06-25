import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ankidroid/main.dart';

void main() {
  testWidgets('shows deck home and creates a local deck', (tester) async {
    await tester.pumpWidget(const AnkiDroidFlutterApp());

    expect(find.text('AnkiDroid'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Japanese');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Japanese'), findsOneWidget);
  });
}
