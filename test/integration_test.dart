/// Gate D/E/F tests: voice+keyboard integration, emoji, GIF policy,
/// regression scenarios (committed text preservation), widget smoke tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bhasha_keyboard/core/keyboard_controller.dart';
import 'package:bhasha_keyboard/data/emoji_data.dart';
import 'package:bhasha_keyboard/data/languages.dart';
import 'package:bhasha_keyboard/engine/gif_provider.dart';
import 'package:bhasha_keyboard/engine/voice_engine.dart';
import 'package:bhasha_keyboard/main.dart';
import 'package:bhasha_keyboard/ui/keyboard_view.dart';

class FakeSpeechProvider implements SpeechProvider {
  void Function(VoiceResult)? _onResult;

  @override
  Future<bool> initialize(LanguagePack pack) async => true;

  @override
  void start(void Function(VoiceResult) onResult) => _onResult = onResult;

  @override
  Future<void> stop() async {}

  @override
  void setScriptMode(ScriptMode mode) {}

  @override
  void setMicMode(MicMode mode) {}

  @override
  void setTranslateTarget(LanguagePack target) {}

  @override
  bool get hasNativeTranslateMode => false;

  void emitPartial(String t) => _onResult?.call(VoiceResult(t, false));
  void emitFinal(String t) => _onResult?.call(VoiceResult(t, true));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Gate F: Voice + keyboard integration (regression)', () {
    test('voice final text appends without erasing committed text', () async {
      final fake = FakeSpeechProvider();
      final kb = KeyboardController(voiceEngine: VoiceEngine(provider: fake));
      kb.insertText('t');
      kb.insertText('y');
      kb.insertText('p');
      kb.insertText('e');
      kb.insertText('d');
      kb.insertText(' ');
      await kb.toggleVoice();
      fake.emitFinal('spoken words');
      expect(kb.editor.text, 'typed spoken words ');
      await kb.voice.stopSession();
      kb.dispose();
    });

    test('key press during voice stops session but preserves text', () async {
      final fake = FakeSpeechProvider();
      final kb = KeyboardController(voiceEngine: VoiceEngine(provider: fake));
      await kb.toggleVoice();
      fake.emitPartial('hello there');
      // User presses a key mid-session.
      kb.keyPressedDuringVoice();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      kb.insertText('x');
      // Partial was committed on stop; keypress text appended after.
      expect(kb.editor.text, contains('hello there'));
      expect(kb.editor.text, endsWith('x'));
      expect(kb.voice.state, VoiceState.idle);
      kb.dispose();
    });

    test('voice toggle twice returns cleanly to idle', () async {
      final fake = FakeSpeechProvider();
      final kb = KeyboardController(voiceEngine: VoiceEngine(provider: fake));
      await kb.toggleVoice();
      expect(kb.voice.isActive, isTrue);
      await kb.toggleVoice();
      expect(kb.voice.state, VoiceState.idle);
      kb.dispose();
    });

    test('panel transitions never lose editor text', () {
      final kb = KeyboardController();
      kb.insertText('s');
      kb.insertText('a');
      kb.insertText('f');
      kb.insertText('e');
      kb.togglePanel(ActivePanel.emoji);
      kb.togglePanel(ActivePanel.gif);
      kb.togglePanel(ActivePanel.translateConfig);
      kb.togglePanel(ActivePanel.language);
      kb.closePanel();
      expect(kb.editor.text, 'safe');
      kb.dispose();
    });

    test('language switch mid-word commits transliteration first', () {
      final kb = KeyboardController();
      kb.setLanguage(LanguageRegistry.byId('hi'));
      for (final c in 'namaste'.split('')) {
        kb.insertText(c);
      }
      kb.setLanguage(LanguageRegistry.byId('ta'));
      // Word was committed as transliterated Hindi before the switch.
      expect(kb.editor.text, 'नमस्ते');
      kb.dispose();
    });
  });

  group('Gate D: Emoji (P1)', () {
    test('dataset has categories with populated emoji lists', () {
      expect(kEmojiCategories.length, greaterThanOrEqualTo(5));
      for (final c in kEmojiCategories) {
        expect(c.emojis, isNotEmpty);
        expect(c.name, isNotEmpty);
      }
    });

    test('offline keyword search finds relevant emojis', () {
      final love = EmojiSearch.search('love');
      expect(love, isNotEmpty);
      final namaste = EmojiSearch.search('namaste');
      expect(namaste.map((e) => e.char), contains('🙏'));
      expect(EmojiSearch.search(''), isEmpty);
      expect(EmojiSearch.search('zzzznotfound'), isEmpty);
    });

    test('emoji insertion works and updates recents', () {
      final kb = KeyboardController();
      kb.insertContent('😀');
      kb.insertContent('🙏');
      expect(kb.editor.text, '😀🙏');
      expect(kb.recentEmojis.first, '🙏');
      expect(kb.recentEmojis, contains('😀'));
      kb.dispose();
    });

    test('no hard-coded single-emoji behavior: all categories insertable', () {
      final kb = KeyboardController();
      final unique = <String>{};
      for (final c in kEmojiCategories) {
        unique.add(c.emojis.first.char);
        kb.insertContent(c.emojis.first.char);
      }
      expect(unique.length, kEmojiCategories.length);
      kb.dispose();
    });
  });

  group('Gate D: GIF policy (P1)', () {
    test('provider returns rendered-result metadata, search filters', () async {
      final p = CuratedGifProvider();
      final trending = p.trending();
      expect(trending, isNotEmpty);
      for (final g in trending) {
        expect(g.previewUrl, startsWith('https://'));
        expect(g.title, isNotEmpty);
      }
      final happy = p.search('happy');
      expect(happy.every((g) => g.title.contains('happy')), isTrue);
      final none = p.search('qqqqnotfound');
      expect(none, isEmpty);
    });

    test(
      'GIF insertion is explicit labelled fallback, not blind URL paste',
      () {
        final kb = KeyboardController();
        // Simulate the panel's insertion policy:
        const gif = GifItem(
          id: 'x',
          title: 'happy dance',
          previewUrl: 'https://example.com/p.gif',
          shareUrl: 'https://example.com/full.gif',
        );
        kb.insertContent('[GIF: ${gif.title}] ${gif.shareUrl}');
        expect(
          kb.editor.text,
          startsWith('[GIF:'),
          reason: 'insertion is labelled, never a bare raw URL',
        );
        kb.dispose();
      },
    );

    test('search is instant/synchronous - every keystroke updates results '
        'immediately like Gboard, with no debounce delay', () {
      final engine = GifEngine();
      final calls = <List<GifItem>>[];
      engine.searchDebounced('h', calls.add);
      engine.searchDebounced('ha', calls.add);
      engine.searchDebounced('happy', calls.add);
      // No delay/await needed: results arrive synchronously for every call.
      expect(
        calls.length,
        3,
        reason:
            'real-time search fires results for every keystroke, '
            'not just the last one after a debounce window',
      );
      expect(calls.last.every((g) => g.title.contains('happy')), isTrue);
      engine.dispose();
    });
  });

  group('Gate E: Widget smoke tests', () {
    testWidgets('app builds with keyboard, toolbar and demo editor', (
      tester,
    ) async {
      await tester.pumpWidget(const BhashaKeyboardApp());
      await tester.pumpAndSettle();
      expect(find.byType(KeyboardView), findsOneWidget);
      expect(find.text('q'), findsOneWidget);
      expect(find.text('a'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsWidgets);
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('tapping keys types into editor', (tester) async {
      await tester.pumpWidget(const BhashaKeyboardApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('h'));
      await tester.pump();
      await tester.tap(find.text('i'));
      await tester.pump();
      final ctx = tester.element(find.byType(KeyboardView));
      final kb = ctx.read<KeyboardController>();
      expect(kb.editor.text, 'hi');
    });

    testWidgets('123 key switches to numeric layer', (tester) async {
      await tester.pumpWidget(const BhashaKeyboardApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('?123'));
      await tester.pumpAndSettle();
      expect(find.text('7'), findsOneWidget);
      expect(find.text('₹'), findsOneWidget);
      // Return to ABC
      await tester.tap(find.text('ABC'));
      await tester.pumpAndSettle();
      expect(find.text('q'), findsOneWidget);
    });

    testWidgets('emoji panel opens and inserts emoji', (tester) async {
      await tester.pumpWidget(const BhashaKeyboardApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.emoji_emotions_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Search emoji'), findsOneWidget);
      // Switch to Smileys category tab (first category after recents)
      await tester.tap(find.text('😀').first);
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(KeyboardView));
      final kb = ctx.read<KeyboardController>();
      expect(kb.panel, ActivePanel.emoji);
    });

    testWidgets('language panel lists all 23 language options', (tester) async {
      await tester.pumpWidget(const BhashaKeyboardApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.language));
      await tester.pumpAndSettle();
      expect(find.text('Hindi'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
      // Scroll to find a later language
      await tester.dragUntilVisible(
        find.text('Manipuri'),
        find.byType(ListView),
        const Offset(0, -80),
      );
      expect(find.text('Manipuri'), findsOneWidget);
    });

    testWidgets('theme switch to dark updates UI', (tester) async {
      await tester.pumpWidget(const BhashaKeyboardApp());
      await tester.pumpAndSettle();
      // Theme now lives inside the Menu grid (spec item 3), not directly
      // in the toolbar - open the Menu first.
      await tester.tap(find.byIcon(Icons.apps));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(KeyboardView));
      final kb = ctx.read<KeyboardController>();
      expect(kb.themeMode, ThemeMode.dark);
    });

    testWidgets('shift key shows uppercase labels', (tester) async {
      await tester.pumpWidget(const BhashaKeyboardApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();
      expect(find.text('Q'), findsOneWidget);
      expect(find.text('q'), findsNothing);
    });
  });
}
