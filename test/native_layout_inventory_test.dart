import 'package:flutter_test/flutter_test.dart';

import 'package:bhasha_keyboard/data/languages.dart';
import 'package:bhasha_keyboard/data/layouts.dart';

void main() {
  test('Native mode exposes the complete Devanagari inventory', () {
    final layout = layoutFor(LanguageRegistry.byId('hi'), ScriptMode.native);
    final characters = layout.rows.expand((row) => row).toSet();

    expect(
      characters,
      containsAll(<String>[
        'अ',
        'आ',
        'इ',
        'ई',
        'क',
        'ख',
        'घ',
        'ण',
        'फ',
        'भ',
        'ळ',
        'ष',
        'ज',
        'ं',
        '्',
        '।',
      ]),
    );
    expect(characters.length, greaterThan(45));
  });

  test('Native mode exposes RTL Arabic-family characters', () {
    final layout = layoutFor(LanguageRegistry.byId('ur'), ScriptMode.native);
    final characters = layout.rows.expand((row) => row).toSet();

    expect(
      characters,
      containsAll(<String>['ا', 'ب', 'پ', 'ٹ', 'ڑ', 'ں', 'ے', '۔']),
    );
  });

  test('Roman mode remains QWERTY for non-Latin languages', () {
    final layout = layoutFor(LanguageRegistry.byId('hi'), ScriptMode.roman);
    expect(layout.rows, kQwerty.rows);
  });
}
