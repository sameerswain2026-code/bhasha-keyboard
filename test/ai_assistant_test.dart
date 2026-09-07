/// Gate G tests: AI Web Assistant (optional, opt-in feature).
///
/// Covers:
///  - Wake-word detection/extraction (pure, stateless logic).
///  - AiAssistantEngine passthrough vs handled-as-command routing,
///    including graceful error handling (never throws).
///  - Gemini AI Router layer: direct answers skip Tavily entirely,
///    "needs search" answers still call the existing Tavily service
///    and then Gemini summarizes the result, and a Gemini outage at
///    either step falls back to the exact pre-Gemini Tavily-only
///    behavior.
///  - KeyboardController integration: disabled by default (zero
///    behavior change to existing voice pipeline), enabled + wake word
///    suppresses the raw command text and inserts the assistant's
///    result instead, Translate mode is left untouched, and non-wake
///    speech in Transcribe/Auto-mix continues to insert exactly as
///    before.
///
/// NOTE: every test below that reaches [AiAssistantEngine]'s query
/// pipeline with a non-empty query supplies a [FakeGeminiService] (most
/// often one configured to throw, i.e. simulating "Gemini unavailable")
/// so tests stay deterministic and offline. This mirrors exactly how
/// [FakeSearchService] already keeps Tavily out of the test run - the
/// throwing fake's only job is to force the engine down its documented
/// fallback path, which is itself asserted to match this engine's
/// original (pre-Gemini) Tavily-only behavior.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bhasha_keyboard/core/keyboard_controller.dart';
import 'package:bhasha_keyboard/data/languages.dart';
import 'package:bhasha_keyboard/engine/ai_assistant_engine.dart';
import 'package:bhasha_keyboard/engine/ai_command_capture.dart';
import 'package:bhasha_keyboard/engine/gemini_service.dart';
import 'package:bhasha_keyboard/engine/tavily_search_service.dart';
import 'package:bhasha_keyboard/engine/voice_engine.dart';
import 'package:bhasha_keyboard/engine/wake_word_detector.dart';

/// Deterministic fake search service - never touches the network.
class FakeSearchService implements TavilySearchService {
  TavilySearchResult? nextResult;
  bool shouldThrow = false;
  String? lastQuery;

  @override
  Future<TavilySearchResult?> search(String query) async {
    lastQuery = query;
    if (shouldThrow) throw Exception('simulated network failure');
    return nextResult;
  }

  @override
  void dispose() {}
}

/// Deterministic fake Gemini service - never touches the network.
///
/// Defaults to [shouldThrow] = false with [needsSearch] = false and an
/// empty [directAnswer], but most existing (pre-Gemini) tests instead
/// set [shouldThrow] = true to force [AiAssistantEngine] down its
/// documented "Gemini unavailable, fall back to Tavily-only" path
/// deterministically.
class FakeGeminiService implements GeminiService {
  bool shouldThrow = false;
  bool needsSearch = false;
  String directAnswer = '';
  String searchQuery = '';
  bool summarizeShouldThrow = false;
  String summarizedAnswer = '';
  String? lastDecideQuery;
  TavilySearchResult? lastSummarizeResult;

  @override
  Future<GeminiDecision> decide(String query, String assistantName) async {
    lastDecideQuery = query;
    if (shouldThrow) throw Exception('simulated Gemini failure');
    return GeminiDecision(
      needsSearch: needsSearch,
      answer: directAnswer,
      searchQuery: searchQuery.isEmpty ? query : searchQuery,
    );
  }

  @override
  Future<String> summarize(
    String query,
    TavilySearchResult result,
    String assistantName,
  ) async {
    lastSummarizeResult = result;
    if (summarizeShouldThrow) {
      throw Exception('simulated Gemini summarize failure');
    }
    return summarizedAnswer.isEmpty
        ? 'Gemini says: ${result.title} - ${result.summary}'
        : summarizedAnswer;
  }

  @override
  Future<String> generateWriting(String prompt) async {
    if (shouldThrow) throw Exception('simulated Gemini failure');
    return directAnswer.isEmpty ? prompt : directAnswer;
  }

  @override
  void dispose() {}
}

/// Fake speech provider (mirrors the one in integration_test.dart) so
/// KeyboardController tests can drive voice finals deterministically.
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

  void emitFinal(String t) => _onResult?.call(VoiceResult(t, true));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Gate G: Wake word detection (pure logic)', () {
    test('no match when wake word absent', () {
      final r = WakeWordDetector.detect('hello how are you', 'Bhasha');
      expect(r.matched, isFalse);
    });

    test('matches wake word at start and strips it', () {
      final r = WakeWordDetector.detect(
        'Bhasha what is the capital of France',
        'Bhasha',
      );
      expect(r.matched, isTrue);
      expect(r.query, 'what is the capital of France');
    });

    test('matches wake word in the middle', () {
      final r = WakeWordDetector.detect('ok Bhasha tell me a joke', 'Bhasha');
      expect(r.matched, isTrue);
      expect(r.query, 'ok tell me a joke');
    });

    test('case-insensitive and punctuation-tolerant', () {
      final r = WakeWordDetector.detect('BHASHA, what time is it', 'bhasha');
      expect(r.matched, isTrue);
      expect(r.query, 'what time is it');
    });

    test('supports custom multi-word assistant names', () {
      final r = WakeWordDetector.detect(
        'hey jarvis search for flutter',
        'Hey Jarvis',
      );
      expect(r.matched, isTrue);
      expect(r.query, 'search for flutter');
    });

    test('wake word spoken alone yields empty query, still matched', () {
      final r = WakeWordDetector.detect('Bhasha', 'Bhasha');
      expect(r.matched, isTrue);
      expect(r.query, isEmpty);
    });

    test('blank wake word never matches', () {
      final r = WakeWordDetector.detect('anything Bhasha here', '   ');
      expect(r.matched, isFalse);
    });
  });

  group('Gate G: AiAssistantEngine routing', () {
    test('disabled engine always passes through, never calls search', () {
      final fake = FakeSearchService();
      final engine = AiAssistantEngine(searchService: fake);
      engine.enabled = false;
      var resultCalled = false;
      final outcome = engine.process(
        'Bhasha what is the weather',
        (_) => resultCalled = true,
      );
      expect(outcome, AiAssistantOutcome.passthrough);
      expect(resultCalled, isFalse);
      expect(fake.lastQuery, isNull);
    });

    test('enabled engine passes through normal speech (no wake word)', () {
      final fake = FakeSearchService();
      final engine = AiAssistantEngine(searchService: fake)..enabled = true;
      final outcome = engine.process(
        'hello how are you today',
        (_) => fail('should not be called'),
      );
      expect(outcome, AiAssistantOutcome.passthrough);
      expect(fake.lastQuery, isNull);
    });

    test('enabled engine + wake word: handled as command, never sends wake '
        'word or raw transcript to search - only the clean query', () async {
      final fake = FakeSearchService()
        ..nextResult = const TavilySearchResult(
          title: 'Capital of France',
          summary: 'Paris is the capital of France.',
          url: 'https://example.com/paris',
        );
      final engine = AiAssistantEngine(
        searchService: fake,
        geminiService: FakeGeminiService()..shouldThrow = true,
      )..enabled = true;
      String? inserted;
      final outcome = engine.process(
        'Bhasha what is the capital of France',
        (text) => inserted = text,
      );
      expect(outcome, AiAssistantOutcome.handledAsCommand);
      // Async result resolution.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fake.lastQuery, 'what is the capital of France');
      expect(fake.lastQuery, isNot(contains('Bhasha')));
      expect(inserted, contains('Capital of France'));
      expect(inserted, contains('Paris is the capital of France.'));
      expect(inserted, contains('https://example.com/paris'));
    });

    test('graceful handling when search throws - no crash', () async {
      final fake = FakeSearchService()..shouldThrow = true;
      final engine = AiAssistantEngine(
        searchService: fake,
        geminiService: FakeGeminiService()..shouldThrow = true,
      )..enabled = true;
      String? inserted;
      engine.process('Bhasha search for something', (text) => inserted = text);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(inserted, isNotNull);
      expect(inserted, isNot(throwsException));
    });

    test('graceful handling when search returns null (no results)', () async {
      final fake = FakeSearchService()..nextResult = null;
      final engine = AiAssistantEngine(
        searchService: fake,
        geminiService: FakeGeminiService()..shouldThrow = true,
      )..enabled = true;
      String? inserted;
      engine.process('Bhasha find nothing useful', (text) => inserted = text);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(inserted, isNotNull);
      expect(inserted, contains("couldn't find"));
    });

    test(
      'wake word alone (empty query) asks for clarification, no search',
      () async {
        final fake = FakeSearchService();
        final engine = AiAssistantEngine(
          searchService: fake,
          geminiService: FakeGeminiService()..shouldThrow = true,
        )..enabled = true;
        String? inserted;
        engine.process('Bhasha', (text) => inserted = text);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fake.lastQuery, isNull);
        expect(inserted, isNotNull);
      },
    );

    test('custom assistant name is respected', () async {
      final fake = FakeSearchService()
        ..nextResult = const TavilySearchResult(
          title: 'T',
          summary: 'S',
          url: '',
        );
      final engine =
          AiAssistantEngine(
              searchService: fake,
              geminiService: FakeGeminiService()..shouldThrow = true,
            )
            ..enabled = true
            ..assistantName = 'Nova';
      final outcome = engine.process('Nova what is the time', (_) {});
      expect(outcome, AiAssistantOutcome.handledAsCommand);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fake.lastQuery, 'what is the time');
      // Old default wake word no longer triggers once renamed.
      final outcome2 = engine.process('Bhasha what is the time', (_) {});
      expect(outcome2, AiAssistantOutcome.passthrough);
    });
  });

  group('Gate G2: Gemini AI Router layer', () {
    test(
      'Gemini decides it can answer directly - Tavily is never called',
      () async {
        final searchFake = FakeSearchService();
        final geminiFake = FakeGeminiService()
          ..needsSearch = false
          ..directAnswer = 'The capital of France is Paris.';
        final engine = AiAssistantEngine(
          searchService: searchFake,
          geminiService: geminiFake,
        )..enabled = true;
        String? inserted;
        final outcome = engine.process(
          'Bhasha what is the capital of France',
          (text) => inserted = text,
        );
        expect(outcome, AiAssistantOutcome.handledAsCommand);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(geminiFake.lastDecideQuery, 'what is the capital of France');
        expect(inserted, 'The capital of France is Paris.');
        // Tavily must never be called when Gemini answers directly.
        expect(searchFake.lastQuery, isNull);
      },
    );

    test('Gemini decides live search is needed - Tavily is called, then '
        'Gemini summarizes the raw result into the final answer', () async {
      final searchFake = FakeSearchService()
        ..nextResult = const TavilySearchResult(
          title: 'Weather Today',
          summary: 'Sunny with a high of 25C.',
          url: 'https://example.com/weather',
        );
      final geminiFake = FakeGeminiService()
        ..needsSearch = true
        ..summarizedAnswer = "It's sunny today with a high of 25C.";
      final engine = AiAssistantEngine(
        searchService: searchFake,
        geminiService: geminiFake,
      )..enabled = true;
      String? inserted;
      engine.process(
        'Bhasha what is the weather today',
        (text) => inserted = text,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(searchFake.lastQuery, 'what is the weather today');
      expect(geminiFake.lastSummarizeResult?.title, 'Weather Today');
      expect(inserted, "It's sunny today with a high of 25C.");
    });

    test('Gemini requests search with a refined search_query - that '
        'refined query (not the original) is sent to Tavily', () async {
      final searchFake = FakeSearchService()
        ..nextResult = const TavilySearchResult(
          title: 'T',
          summary: 'S',
          url: '',
        );
      final geminiFake = FakeGeminiService()
        ..needsSearch = true
        ..searchQuery = 'refined focused query';
      final engine = AiAssistantEngine(
        searchService: searchFake,
        geminiService: geminiFake,
      )..enabled = true;
      engine.process('Bhasha tell me something', (_) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(searchFake.lastQuery, 'refined focused query');
    });

    test('Gemini decide() fails - falls back to the original Tavily-only '
        'pipeline with the plain title/summary/url formatting', () async {
      final searchFake = FakeSearchService()
        ..nextResult = const TavilySearchResult(
          title: 'Fallback Title',
          summary: 'Fallback summary text.',
          url: 'https://example.com/fallback',
        );
      final geminiFake = FakeGeminiService()..shouldThrow = true;
      final engine = AiAssistantEngine(
        searchService: searchFake,
        geminiService: geminiFake,
      )..enabled = true;
      String? inserted;
      engine.process(
        'Bhasha what is the fallback answer',
        (text) => inserted = text,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(searchFake.lastQuery, 'what is the fallback answer');
      expect(inserted, contains('Fallback Title'));
      expect(inserted, contains('Fallback summary text.'));
      expect(inserted, contains('https://example.com/fallback'));
    });

    test('Gemini needs search but its summarize() step fails - falls back '
        'to the plain title/summary/url formatting rather than dropping '
        "Tavily's (successful) result", () async {
      final searchFake = FakeSearchService()
        ..nextResult = const TavilySearchResult(
          title: 'Raw Result',
          summary: 'Raw summary.',
          url: 'https://example.com/raw',
        );
      final geminiFake = FakeGeminiService()
        ..needsSearch = true
        ..summarizeShouldThrow = true;
      final engine = AiAssistantEngine(
        searchService: searchFake,
        geminiService: geminiFake,
      )..enabled = true;
      String? inserted;
      engine.process(
        'Bhasha search for something live',
        (text) => inserted = text,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(inserted, contains('Raw Result'));
      expect(inserted, contains('Raw summary.'));
    });

    test('Gemini says no search needed but gives no answer either - still '
        'falls back to Tavily rather than inserting nothing', () async {
      final searchFake = FakeSearchService()
        ..nextResult = const TavilySearchResult(
          title: 'Backstop',
          summary: 'Backstop summary.',
          url: '',
        );
      final geminiFake = FakeGeminiService()
        ..needsSearch = false
        ..directAnswer = '';
      final engine = AiAssistantEngine(
        searchService: searchFake,
        geminiService: geminiFake,
      )..enabled = true;
      String? inserted;
      engine.process('Bhasha give me something', (text) => inserted = text);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(searchFake.lastQuery, 'give me something');
      expect(inserted, contains('Backstop'));
    });
  });

  group('Gate G: KeyboardController integration', () {
    test('assistant OFF by default: voice text inserts exactly as before, '
        'even if it happens to contain the word "Bhasha"', () async {
      final fake = FakeSpeechProvider();
      final kb = KeyboardController(voiceEngine: VoiceEngine(provider: fake));
      expect(kb.aiAssistantEnabled, isFalse);
      await kb.toggleVoice();
      fake.emitFinal('Bhasha what time is it');
      expect(kb.editor.text.trim(), 'Bhasha what time is it');
      kb.dispose();
    });

    test('assistant ON + wake word: raw command text is NOT inserted, '
        'formatted result is inserted instead', () async {
      final searchFake = FakeSearchService()
        ..nextResult = const TavilySearchResult(
          title: 'Weather Today',
          summary: 'Sunny with a high of 25C.',
          url: 'https://example.com/weather',
        );
      final aiEngine = AiAssistantEngine(
        searchService: searchFake,
        geminiService: FakeGeminiService()..shouldThrow = true,
      )..enabled = true;
      final fake = FakeSpeechProvider();
      final kb = KeyboardController(
        voiceEngine: VoiceEngine(provider: fake),
        aiEngine: aiEngine,
      );
      kb.setAiAssistantEnabled(true);
      await kb.toggleVoice();
      fake.emitFinal('Bhasha what is the weather today');
      // Raw command text must never appear.
      expect(kb.editor.text, isNot(contains('what is the weather today')));
      // AI command capture buffers the wake-word utterance until the mic
      // stops or the inactivity timeout elapses (see AiCommandCapture) -
      // stopping the mic session is the "mic stops" finalize trigger.
      await kb.voice.stopSession();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(kb.editor.text, contains('Weather Today'));
      expect(kb.editor.text, contains('Sunny with a high of 25C.'));
      expect(kb.editor.text, contains('https://example.com/weather'));
      kb.dispose();
    });

    test(
      'assistant ON but no wake word: normal speech still inserted as usual',
      () async {
        final searchFake = FakeSearchService();
        final aiEngine = AiAssistantEngine(searchService: searchFake)
          ..enabled = true;
        final fake = FakeSpeechProvider();
        final kb = KeyboardController(
          voiceEngine: VoiceEngine(provider: fake),
          aiEngine: aiEngine,
        );
        kb.setAiAssistantEnabled(true);
        await kb.toggleVoice();
        fake.emitFinal('just some normal speech');
        expect(kb.editor.text.trim(), 'just some normal speech');
        expect(searchFake.lastQuery, isNull);
        kb.dispose();
      },
    );

    test('setAssistantName updates the wake word used for detection', () async {
      final searchFake = FakeSearchService()
        ..nextResult = const TavilySearchResult(
          title: 'T',
          summary: 'S',
          url: '',
        );
      final aiEngine = AiAssistantEngine(
        searchService: searchFake,
        geminiService: FakeGeminiService()..shouldThrow = true,
      )..enabled = true;
      final fake = FakeSpeechProvider();
      final kb = KeyboardController(
        voiceEngine: VoiceEngine(provider: fake),
        aiEngine: aiEngine,
      );
      kb.setAiAssistantEnabled(true);
      kb.setAssistantName('Nova');
      expect(kb.assistantName, 'Nova');
      await kb.toggleVoice();
      fake.emitFinal('Nova search for dart language');
      await kb.voice.stopSession();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(searchFake.lastQuery, 'search for dart language');
      kb.dispose();
    });

    test('blank assistant name is rejected, keeps previous value', () {
      final kb = KeyboardController();
      final original = kb.assistantName;
      kb.setAssistantName('   ');
      expect(kb.assistantName, original);
      kb.dispose();
    });

    test('Translate mode is left untouched: wake word is not intercepted '
        'even when the assistant is enabled', () async {
      final searchFake = FakeSearchService();
      final aiEngine = AiAssistantEngine(searchService: searchFake)
        ..enabled = true;
      final fake = FakeSpeechProvider();
      final kb = KeyboardController(
        voiceEngine: VoiceEngine(provider: fake),
        aiEngine: aiEngine,
      );
      kb.setAiAssistantEnabled(true);
      kb.applyTranslateConfig(); // switches mic mode to Translate
      expect(kb.micMode, MicMode.translate);
      await kb.toggleVoice();
      fake.emitFinal('Bhasha this should not be intercepted');
      // SimulatedTranslationProvider has an internal ~120ms latency (see
      // translation_engine.dart) - wait past it before asserting/
      // disposing, otherwise the pivot-translation Future can still be
      // in flight when kb.dispose() tears down the TextEditingController.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      // Translate mode's existing pivot-translation path handled it,
      // not the AI assistant - confirm Tavily was never queried.
      expect(searchFake.lastQuery, isNull);
      kb.dispose();
    });

    test(
      'AI assistant enabled state and name persist across sessions',
      () async {
        SharedPreferences.setMockInitialValues({});
        final kb1 = KeyboardController();
        kb1.setAiAssistantEnabled(true);
        kb1.setAssistantName('Nova');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        kb1.dispose();

        final kb2 = KeyboardController();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(kb2.aiAssistantEnabled, isTrue);
        expect(kb2.assistantName, 'Nova');
        kb2.dispose();
      },
    );
  });

  group('Gate G3: AI command capture (buffer + configurable timeout)', () {
    // The previous group's last test ('AI assistant enabled state and
    // name persist across sessions') deliberately leaves the mock
    // SharedPreferences store holding assistantName='Nova'. Reset it
    // here so every test below starts from a clean slate and the
    // default wake word ("Bhasha") is the one actually in effect,
    // matching what a fresh install would see.
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default listening timeout is Balanced (5s)', () {
      final kb = KeyboardController();
      expect(kb.aiListeningTimeout, AiListeningTimeout.balanced);
      kb.dispose();
    });

    test('aiCapturing/aiThinking reflect a full capture lifecycle: idle -> '
        'capturing (wake word heard) -> thinking (mic stopped, AI Router '
        'in flight) -> idle again once the response is inserted (AI mode '
        'auto-exits)', () async {
      final searchFake = FakeSearchService()
        ..nextResult = const TavilySearchResult(
          title: 'Weather Today',
          summary: 'Sunny.',
          url: 'https://example.com/weather',
        );
      final aiEngine = AiAssistantEngine(
        searchService: searchFake,
        geminiService: FakeGeminiService()..shouldThrow = true,
      )..enabled = true;
      final fake = FakeSpeechProvider();
      final kb = KeyboardController(
        voiceEngine: VoiceEngine(provider: fake),
        aiEngine: aiEngine,
      );
      kb.setAiAssistantEnabled(true);

      expect(kb.aiCapturing, isFalse);
      expect(kb.aiThinking, isFalse);

      await kb.toggleVoice();
      fake.emitFinal('Bhasha what is the weather today');
      // Wake word heard -> now buffering, not yet thinking.
      expect(kb.aiCapturing, isTrue);
      expect(kb.aiThinking, isFalse);

      await kb.voice.stopSession();
      // Mic stopped -> capture finalizes -> AI Router call in flight.
      expect(kb.aiCapturing, isFalse);
      expect(kb.aiThinking, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 300));
      // Response delivered -> AI mode auto-exits.
      expect(kb.aiThinking, isFalse);
      expect(kb.aiCapturing, isFalse);
      expect(kb.editor.text, contains('Weather Today'));
      kb.dispose();
    });

    test('multi-chunk buffering: several finalized speech chunks after '
        'the wake word are concatenated into ONE utterance sent to the AI '
        'Router exactly once, not once per chunk', () async {
      final searchFake = FakeSearchService()
        ..nextResult = const TavilySearchResult(
          title: 'T',
          summary: 'S',
          url: '',
        );
      final geminiFake = FakeGeminiService()..shouldThrow = true;
      final aiEngine = AiAssistantEngine(
        searchService: searchFake,
        geminiService: geminiFake,
      )..enabled = true;
      final fake = FakeSpeechProvider();
      final kb = KeyboardController(
        voiceEngine: VoiceEngine(provider: fake),
        aiEngine: aiEngine,
      );
      kb.setAiAssistantEnabled(true);
      await kb.toggleVoice();

      fake.emitFinal('Bhasha search for');
      fake.emitFinal('the best flutter');
      fake.emitFinal('packages available');
      await kb.voice.stopSession();
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Exactly one search call, with the FULL concatenated command
      // (minus the wake word), never a per-chunk call.
      expect(
        searchFake.lastQuery,
        'search for the best flutter packages available',
      );
      kb.dispose();
    });

    test(
      'setAiListeningTimeout persists and applies instantly (no '
      'restart needed) - a fresh controller loads the saved preset',
      () async {
        SharedPreferences.setMockInitialValues({});
        final kb1 = KeyboardController();
        expect(kb1.aiListeningTimeout, AiListeningTimeout.balanced);
        kb1.setAiListeningTimeout(AiListeningTimeout.extended);
        // Applies instantly - no async wait needed to observe the change
        // on the same controller instance.
        expect(kb1.aiListeningTimeout, AiListeningTimeout.extended);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        kb1.dispose();

        final kb2 = KeyboardController();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(kb2.aiListeningTimeout, AiListeningTimeout.extended);
        kb2.dispose();
      },
    );

    test(
      'disabling the AI assistant mid-capture cancels the in-progress '
      'buffered command cleanly (no stale AI Router call fires later)',
      () async {
        final searchFake = FakeSearchService();
        final aiEngine = AiAssistantEngine(
          searchService: searchFake,
          geminiService: FakeGeminiService()..shouldThrow = true,
        )..enabled = true;
        final fake = FakeSpeechProvider();
        final kb = KeyboardController(
          voiceEngine: VoiceEngine(provider: fake),
          aiEngine: aiEngine,
        );
        kb.setAiAssistantEnabled(true);
        await kb.toggleVoice();
        fake.emitFinal('Bhasha search for something');
        expect(kb.aiCapturing, isTrue);

        kb.setAiAssistantEnabled(false);
        expect(kb.aiCapturing, isFalse);
        expect(kb.aiThinking, isFalse);

        // Even if the mic session ends afterwards, no stale finalize/AI
        // call should ever fire since the capture was cancelled.
        await kb.voice.stopSession();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(searchFake.lastQuery, isNull);
        kb.dispose();
      },
    );

    test('changing the listening timeout applies to the NEXT capture '
        'immediately - no restart needed', () async {
      final searchFake = FakeSearchService()
        ..nextResult = const TavilySearchResult(
          title: 'T',
          summary: 'S',
          url: '',
        );
      final aiEngine = AiAssistantEngine(
        searchService: searchFake,
        geminiService: FakeGeminiService()..shouldThrow = true,
      )..enabled = true;
      final fake = FakeSpeechProvider();
      final kb = KeyboardController(
        voiceEngine: VoiceEngine(provider: fake),
        aiEngine: aiEngine,
      );
      kb.setAiAssistantEnabled(true);
      kb.setAiListeningTimeout(AiListeningTimeout.fast);

      await kb.toggleVoice();
      fake.emitFinal('Bhasha search for fast timeout test');
      expect(kb.aiCapturing, isTrue);
      // Fast preset (3s) - well under the default silence timeout, so
      // auto-finalizes via the AI capture's own inactivity timer without
      // needing an explicit stopSession() call.
      await Future<void>.delayed(const Duration(seconds: 3, milliseconds: 200));
      expect(kb.aiCapturing, isFalse);
      expect(searchFake.lastQuery, 'search for fast timeout test');
      kb.dispose();
    });
  });
}
