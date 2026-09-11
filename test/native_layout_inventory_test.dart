import 'package:flutter_test/flutter_test.dart';

import 'package:bhasha_keyboard/data/languages.dart';
import 'package:bhasha_keyboard/data/layouts.dart';

void main() {
  test(
    'Native mode exposes the complete Devanagari inventory across pages',
    () {
      final pages = nativePageCount(
        LanguageRegistry.byId('hi'),
        ScriptMode.native,
      );
      final characters = <String>{};
      for (var page = 0; page < pages; page++) {
        final layout = layoutPageFor(
          LanguageRegistry.byId('hi'),
          ScriptMode.native,
          page,
        );
        expect(layout.rows[0].length, lessThanOrEqualTo(10));
        expect(layout.rows[1].length, lessThanOrEqualTo(9));
        expect(layout.rows[2].length, lessThanOrEqualTo(7));
        characters.addAll(layout.rows.expand((row) => row));
      }
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
    },
  );

  test('Native mode exposes RTL Arabic-family characters', () {
    final pack = LanguageRegistry.byId('ur');
    final characters = <String>{};
    for (
      var page = 0;
      page < nativePageCount(pack, ScriptMode.native);
      page++
    ) {
      characters.addAll(
        layoutPageFor(pack, ScriptMode.native, page).rows.expand((row) => row),
      );
    }
    expect(
      characters,
      containsAll(<String>['ا', 'ب', 'پ', 'ٹ', 'ت', 'ک', 'ی', 'ے']),
    );
  });

  test('Roman mode remains QWERTY for non-Latin languages', () {
    final layout = layoutFor(LanguageRegistry.byId('hi'), ScriptMode.roman);
    expect(layout.rows, kQwerty.rows);
  });
}
