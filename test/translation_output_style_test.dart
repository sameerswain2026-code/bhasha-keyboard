import 'package:flutter_test/flutter_test.dart';

import 'package:bhasha_keyboard/data/languages.dart';
import 'package:bhasha_keyboard/engine/transliterator.dart';

void main() {
  test('romanize preserves readable output for Devanagari', () {
    final hindi = LanguageRegistry.byId('hi');
    expect(Transliterator.romanize('नमस्ते', hindi), contains('nam'));
    expect(Transliterator.romanize('नमस्ते', hindi), isNot(contains('न')));
  });

  test('romanize maps common Urdu characters and preserves punctuation', () {
    final urdu = LanguageRegistry.byId('ur');
    expect(Transliterator.romanize('پاکستان۔', urdu), 'pakistan۔');
  });

  test('latin output remains unchanged', () {
    final english = LanguageRegistry.byId('en');
    expect(Transliterator.romanize('hello!', english), 'hello!');
  });
}
