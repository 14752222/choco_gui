import 'package:flutter_test/flutter_test.dart';
import 'package:choco_gui/app.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChocoApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
