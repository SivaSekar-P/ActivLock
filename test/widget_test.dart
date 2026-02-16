import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:activ_lock/main.dart';

void main() {
  testWidgets('Dashboard rendering smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We must wrap the app in a ProviderScope because ActivLock uses Riverpod.
    await tester.pumpWidget(const ProviderScope(child: ActivLockApp()));

    // Allow time for any initial animations or loads
    await tester.pump();

    // Verify that the specific ActivLock Dashboard title is present.
    expect(find.text('ACTIVLOCK PROTOCOL'), findsOneWidget);

    // Verify that the empty state message shows up (since no apps are locked yet).
    expect(find.text('NO ACTIVE PROTOCOLS'), findsOneWidget);

    // Verify the Floating Action Button (Shield Icon) is present.
    expect(find.byIcon(Icons.shield), findsOneWidget);
  });
}