import '../lib/data/languages.dart';
import '../lib/engine/transliterator.dart';

void main() {
  final hindi = LanguageRegistry.byId('hi');
  final urdu = LanguageRegistry.byId('ur');
  final hindiRoman = Transliterator.romanize('नमस्ते', hindi);
  final urduRoman = Transliterator.romanize('پاکستان۔', urdu);
  if (hindiRoman.contains('न') || hindiRoman.isEmpty) {
    throw StateError('Hindi Romanization failed: $hindiRoman');
  }
  if (urduRoman != 'pakstan۔') {
    throw StateError('Urdu Romanization failed: $urduRoman');
  }
  print('translation smoke passed: $hindiRoman / $urduRoman');
}
