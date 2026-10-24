import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parakh/core/theme/parakh_theme.dart';

void main() {
  testWidgets('Parakh theme loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ParakhTheme.light,
        home: const Scaffold(body: Center(child: Text('Parakh'))),
      ),
    );

    expect(find.text('Parakh'), findsOneWidget);
  });
}
