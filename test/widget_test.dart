import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clone_app/main.dart';

void main() {
  testWidgets('QuikchexPortalApp initial login screen test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const QuikchexPortalApp());
    await tester.pump();

    // Verify Login Screen elements
    expect(find.text('Workforce Intelligence Portal'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('MainPortalScreen smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: MainPortalScreen(),
      ),
    );
    await tester.pump();

    // Verify Welcome title and brand copyright in portal
    expect(find.text('Welcome, Pratik Nikam'), findsOneWidget);
    expect(find.text('COPYRIGHT © 2026 LOGILEAD TECHNOLOGIES. ALL RIGHTS RESERVED.'), findsOneWidget);
  });
}

