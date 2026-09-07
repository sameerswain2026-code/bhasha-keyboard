/// Writing transformations powered by the existing Gemini service.
library;

import 'gemini_service.dart';

enum WritingAction { grammar, rewrite, professional, friendly, concise, reply }

class WritingAssistant {
  WritingAssistant({GeminiService? gemini}) : _gemini = gemini ?? GeminiService();
  final GeminiService _gemini;

  Future<String> transform(String text, WritingAction action) {
    final instruction = switch (action) {
      WritingAction.grammar => 'Correct grammar, spelling, punctuation, and natural phrasing.',
      WritingAction.rewrite => 'Rewrite this clearly while preserving the exact meaning.',
      WritingAction.professional => 'Rewrite this in a polished professional tone.',
      WritingAction.friendly => 'Rewrite this in a warm, friendly, natural tone.',
      WritingAction.concise => 'Make this concise without losing important meaning.',
      WritingAction.reply => 'Write one short, appropriate reply to this message.',
    };
    return _gemini.generateWriting(
      'You are a writing assistant inside a mobile keyboard. $instruction '
      'Return only the final text, with no explanation or quotation marks.\n\n'
      'Text:\n$text',
    );
  }

  void dispose() => _gemini.dispose();
}
