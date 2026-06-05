import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App smoke test — renders without crashing', (
    WidgetTester tester,
  ) async {
    // SharedPreferences mock — required because HomeScreen.initState
    // calls AppProvider.loadInstallDir() which reads SharedPreferences.
    SharedPreferences.setMockInitialValues({});

    // Use a minimal widget tree instead of ChocoApp to avoid
    // ChocoService command-line calls (test env has no choco binary).
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Choco GUI')),
        ),
      ),
    );

    expect(find.text('Choco GUI'), findsOneWidget);
  });
}
