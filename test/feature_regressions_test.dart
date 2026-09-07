import 'package:flutter_test/flutter_test.dart';
import 'package:bhasha_keyboard/data/languages.dart';
import 'package:bhasha_keyboard/engine/translation_engine.dart';
import 'package:bhasha_keyboard/engine/writing_assistant.dart';

void main() {
  test('auto detector identifies distinct Indic scripts', () {
    final engine = TranslationEngine();
    expect(engine.detectLanguage('வணக்கம்').id, 'ta');
    expect(engine.detectLanguage('తెలుగు').id, 'te');
    expect(engine.detectLanguage('नमस्ते').id, 'hi');
    expect(
      engine.detectLanguage('hello', fallback: LanguageRegistry.byId('mr')).id,
      'mr',
    );
  });

  test('writing actions expose the requested keyboard transformations', () {
    expect(WritingAction.values, contains(WritingAction.grammar));
    expect(WritingAction.values, contains(WritingAction.rewrite));
    expect(WritingAction.values, contains(WritingAction.professional));
    expect(WritingAction.values, contains(WritingAction.friendly));
    expect(WritingAction.values, contains(WritingAction.reply));
  });
}
