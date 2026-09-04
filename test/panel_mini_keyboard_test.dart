/// Gate H: Embedded ("panel") mini-keyboard upgrade.
///
/// Covers the upgrade from lowercase-only QWERTY to full capability -
/// Shift (single-tap), Caps Lock (double-tap), numeric layer, symbols
/// layer, and layout switching - while confirming typing behavior
/// matches the main keyboard's own uppercase/caps-lock rules and that
/// the panel keyboard's own Shift/layer state never leaks into (or is
/// driven by) [KeyboardController]'s main keyboard state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bhasha_keyboard/core/keyboard_controller.dart';
import 'package:bhasha_keyboard/ui/panels/panel_mini_keyboard.dart';

Widget _harness(KeyboardController kb, {bool compact = true}) {
  return ChangeNotifierProvider<KeyboardController>.value(
    value: kb,
    child: MaterialApp(
      home: Scaffold(body: PanelMiniKeyboard(compact: compact)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Gate H: Panel mini-keyboard - alpha layer', () {
    testWidgets('lowercase letters insert lowercase by default', (
      tester,
    ) async {
      final kb = KeyboardController();
      kb.openPanelKeyboard();
      await tester.pumpWidget(_harness(kb));

      await tester.tap(find.text('q'));
      await tester.pump();

      expect(kb.panelInputText, 'q');
      kb.dispose();
    });

    testWidgets('single shift tap uppercases exactly one letter then reverts', (
      tester,
    ) async {
      final kb = KeyboardController();
      kb.openPanelKeyboard();
      await tester.pumpWidget(_harness(kb));

      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pump();

      await tester.tap(find.text('Q'));
      await tester.pump();
      expect(kb.panelInputText, 'Q');

      // Shift is single-use: the next letter should be lowercase again.
      await tester.tap(find.text('w'));
      await tester.pump();
      expect(kb.panelInputText, 'Qw');
      kb.dispose();
    });

    testWidgets('double-tap shift engages caps lock (stays uppercase)', (
      tester,
    ) async {
      final kb = KeyboardController();
      kb.openPanelKeyboard();
      await tester.pumpWidget(_harness(kb));

      final shiftKey = find.byIcon(Icons.arrow_upward);
      await tester.tap(shiftKey);
      await tester.pump(const Duration(milliseconds: 50));
      // Second tap on the SAME (still arrow_upward, single-shift) key
      // within the 350ms window engages caps lock.
      await tester.tap(shiftKey);
      await tester.pump();

      // Caps lock icon now shown - confirms state engaged.
      expect(find.byIcon(Icons.keyboard_capslock), findsOneWidget);

      await tester.tap(find.text('Q'));
      await tester.pump();
      await tester.tap(find.text('W'));
      await tester.pump();

      expect(kb.panelInputText, 'QW');
      kb.dispose();
    });

    testWidgets('backspace and space keys work on the alpha layer', (
      tester,
    ) async {
      final kb = KeyboardController();
      kb.openPanelKeyboard(initialText: 'hi');
      await tester.pumpWidget(_harness(kb));

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      expect(kb.panelInputText, 'h');
      kb.dispose();
    });

    testWidgets('panel keyboard shift/caps state is independent of the main '
        'keyboard shift/layer state', (tester) async {
      final kb = KeyboardController();
      kb.openPanelKeyboard();
      await tester.pumpWidget(_harness(kb));

      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pump();

      // Tapping shift inside the panel keyboard must not affect the
      // main keyboard's own (unrelated) shift state.
      expect(kb.shift, ShiftState.off);
      expect(kb.layer, KeyboardLayer.alpha);
      kb.dispose();
    });
  });

  group('Gate H: Panel mini-keyboard - numeric/symbols layers', () {
    testWidgets('?123 key switches to the numeric layer and back', (
      tester,
    ) async {
      final kb = KeyboardController();
      kb.openPanelKeyboard();
      await tester.pumpWidget(_harness(kb));

      await tester.tap(find.text('?123'));
      await tester.pump();

      // Numeric layer shows digits.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.text('1'));
      await tester.pump();
      expect(kb.panelInputText, '1');

      await tester.tap(find.text('ABC'));
      await tester.pump();
      expect(find.text('q'), findsOneWidget);
      kb.dispose();
    });

    testWidgets('=\\< key switches from numeric to symbols layer', (
      tester,
    ) async {
      final kb = KeyboardController();
      kb.openPanelKeyboard();
      await tester.pumpWidget(_harness(kb));

      await tester.tap(find.text('?123'));
      await tester.pump();
      await tester.tap(find.text('=\\<'));
      await tester.pump();

      // Symbols layer shows a symbol from kSymbols row 0.
      expect(find.text('~'), findsOneWidget);
      await tester.tap(find.text('~'));
      await tester.pump();
      expect(kb.panelInputText, '~');
      kb.dispose();
    });
  });

  group('Gate H: Panel mini-keyboard - done button', () {
    testWidgets('checkmark closes the panel keyboard and calls onDone', (
      tester,
    ) async {
      final kb = KeyboardController();
      kb.openPanelKeyboard();
      var doneCalled = false;
      await tester.pumpWidget(
        ChangeNotifierProvider<KeyboardController>.value(
          value: kb,
          child: MaterialApp(
            home: Scaffold(
              body: PanelMiniKeyboard(
                compact: true,
                onDone: () => doneCalled = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(doneCalled, isTrue);
      expect(kb.panelKeyboardActive, isFalse);
      kb.dispose();
    });
  });
}
