import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:droob_alittihad/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    expect(find.text('بلدية محافظة الخرج'), findsOneWidget);
  });
}
