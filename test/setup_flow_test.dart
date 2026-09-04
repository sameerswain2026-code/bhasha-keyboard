/// Gate B/E: Android setup flow screen (enable IME, select IME, mic
/// permission). Runs on the host VM (not a real Android device) so
/// ImeSetupHelper's platform channel calls throw and safely resolve to
/// `false` per-step - this test verifies the resulting UI reflects that
/// "not yet done" state correctly and every action is reachable.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bhasha_keyboard/ui/setup_flow_screen.dart';

void main() {
  group('Gate B: Android setup flow', () {
    testWidgets('shows all three steps with pending status', (tester) async {
      var continued = false;
      await tester.pumpWidget(
        MaterialApp(home: SetupFlowScreen(onContinue: () => continued = true)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Enable the keyboard'), findsOneWidget);
      expect(find.textContaining('Select as active keyboard'), findsOneWidget);
      expect(find.textContaining('Allow microphone access'), findsOneWidget);

      // No platform channel implementation in tests -> every step defaults
      // to not-done, so all three action buttons are present and enabled.
      expect(find.text('Open settings'), findsOneWidget);
      expect(find.text('Choose keyboard'), findsOneWidget);
      expect(find.text('Grant permission'), findsOneWidget);

      // "Skip for now" is always available; never traps the user.
      expect(find.text('Skip for now'), findsOneWidget);
      await tester.tap(find.text('Skip for now'));
      await tester.pump();
      expect(continued, isTrue);
    });

    testWidgets('every visible control is tappable without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: SetupFlowScreen(onContinue: () {})),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose keyboard'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grant permission'));
      await tester.pumpAndSettle();

      // Screen remains usable (no crash, no hidden state).
      expect(find.byType(SetupFlowScreen), findsOneWidget);
    });
  });
}
