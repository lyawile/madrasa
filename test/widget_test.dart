import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madrasa/main.dart';

void main() {
  testWidgets('Madrasa app layout and navigation test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MadrasaApp());

    // Verify that the navigation tabs exist by their label text
    expect(find.text('Attendance'), findsAtLeastNWidgets(1));
    expect(find.text('Registration'), findsAtLeastNWidgets(1));

    // Verify that we start on the Attendance tab by checking for the App Bar header title
    expect(find.text('Daily Attendance'), findsOneWidget);
  });
}
