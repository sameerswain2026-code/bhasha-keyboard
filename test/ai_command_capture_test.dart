/// Unit tests for [AiCommandCapture] - the multi-chunk AI voice command
/// buffer that finalizes only when the mic stops (via [finalizeNow]) or
/// the configured inactivity timeout elapses (via an internal [Timer]).
///
/// These tests exercise the module in complete isolation (no
/// [KeyboardController], no [VoiceEngine], no fakes needed) since
/// [AiCommandCapture] itself has zero dependencies beyond `dart:async`.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:bhasha_keyboard/engine/ai_command_capture.dart';

void main() {
  group('AiListeningTimeout', () {
    test('has exactly 4 presets with the expected durations/labels', () {
      expect(AiListeningTimeout.values.length, 4);
      expect(AiListeningTimeout.fast.duration, const Duration(seconds: 3));
      expect(AiListeningTimeout.fast.label, 'Fast');
      expect(AiListeningTimeout.balanced.duration, const Duration(seconds: 5));
      expect(AiListeningTimeout.balanced.label, 'Balanced');
      expect(AiListeningTimeout.patient.duration, const Duration(seconds: 7));
      expect(AiListeningTimeout.patient.label, 'Patient');
      expect(AiListeningTimeout.extended.duration, const Duration(seconds: 10));
      expect(AiListeningTimeout.extended.label, 'Extended');
    });

    test('fromName resolves each enum by its .name for safe persistence', () {
      for (final t in AiListeningTimeout.values) {
        expect(AiListeningTimeout.fromName(t.name), t);
      }
    });

    test('fromName falls back to balanced (default) for null/unknown', () {
      expect(AiListeningTimeout.fromName(null), AiListeningTimeout.balanced);
      expect(
        AiListeningTimeout.fromName('not_a_real_value'),
        AiListeningTimeout.balanced,
      );
      expect(AiListeningTimeout.fromName(''), AiListeningTimeout.balanced);
    });
  });

  group('AiCommandCapture: state machine', () {
    test('starts idle, not capturing', () {
      final c = AiCommandCapture();
      expect(c.state, AiCaptureState.idle);
      expect(c.isCapturing, isFalse);
      c.dispose();
    });

    test('start() transitions to capturing and fires onCaptureStart once', () {
      final c = AiCommandCapture(timeout: const Duration(seconds: 30));
      var startCalls = 0;
      c.onCaptureStart = () => startCalls++;
      c.start('what is the weather');
      expect(c.state, AiCaptureState.capturing);
      expect(c.isCapturing, isTrue);
      expect(startCalls, 1);
      c.dispose();
    });

    test('cancel() returns to idle and fires onCaptureEnd exactly once', () {
      final c = AiCommandCapture(timeout: const Duration(seconds: 30));
      var endCalls = 0;
      c.onCaptureEnd = () => endCalls++;
      c.start('hello');
      c.cancel();
      expect(c.state, AiCaptureState.idle);
      expect(endCalls, 1);
      // Cancelling again (already idle) must be a no-op - no double-fire.
      c.cancel();
      expect(endCalls, 1);
      c.dispose();
    });

    test('cancel() before start() is a safe no-op', () {
      final c = AiCommandCapture();
      var endCalls = 0;
      c.onCaptureEnd = () => endCalls++;
      c.cancel();
      expect(c.state, AiCaptureState.idle);
      expect(endCalls, 0);
      c.dispose();
    });
  });

  group('AiCommandCapture: buffering + finalize', () {
    test('finalizeNow() delivers exactly the first chunk when no feed() '
        'calls happened', () {
      final c = AiCommandCapture(timeout: const Duration(seconds: 30));
      String? delivered;
      c.onFinalize = (text) => delivered = text;
      c.start('what is the capital of France');
      c.finalizeNow();
      expect(delivered, 'what is the capital of France');
      expect(c.state, AiCaptureState.idle);
      c.dispose();
    });

    test('feed() concatenates multiple chunks with single-space separators '
        'in arrival order, delivered as one utterance on finalize', () {
      final c = AiCommandCapture(timeout: const Duration(seconds: 30));
      String? delivered;
      c.onFinalize = (text) => delivered = text;
      c.start('search for');
      c.feed('the best');
      c.feed('flutter packages');
      c.finalizeNow();
      expect(delivered, 'search for the best flutter packages');
      c.dispose();
    });

    test('feed() while idle (no active capture) is ignored', () {
      final c = AiCommandCapture();
      var finalizeCalls = 0;
      c.onFinalize = (_) => finalizeCalls++;
      c.feed('should be ignored, nothing started yet');
      expect(finalizeCalls, 0);
      expect(c.state, AiCaptureState.idle);
      c.dispose();
    });

    test('feed() with blank/whitespace-only chunk is ignored (no extra '
        'spaces injected into the buffered utterance)', () {
      final c = AiCommandCapture(timeout: const Duration(seconds: 30));
      String? delivered;
      c.onFinalize = (text) => delivered = text;
      c.start('hello world');
      c.feed('   ');
      c.feed('');
      c.finalizeNow();
      expect(delivered, 'hello world');
      c.dispose();
    });

    test('finalizeNow() fires onCaptureEnd before onFinalize, and both '
        'exactly once', () {
      final c = AiCommandCapture(timeout: const Duration(seconds: 30));
      final order = <String>[];
      c.onCaptureEnd = () => order.add('end');
      c.onFinalize = (_) => order.add('finalize');
      c.start('test');
      c.finalizeNow();
      expect(order, ['end', 'finalize']);
      c.dispose();
    });

    test('finalizeNow() on an empty/whitespace-only buffered utterance '
        'still ends the capture cleanly but never calls onFinalize (avoids '
        'a wasted AI Router call for a no-content command)', () {
      final c = AiCommandCapture(timeout: const Duration(seconds: 30));
      var finalizeCalls = 0;
      var endCalls = 0;
      c.onFinalize = (_) => finalizeCalls++;
      c.onCaptureEnd = () => endCalls++;
      c.start('   ');
      c.finalizeNow();
      expect(finalizeCalls, 0);
      expect(endCalls, 1);
      expect(c.state, AiCaptureState.idle);
      c.dispose();
    });

    test('finalizeNow() while idle (no active capture) is a safe no-op', () {
      final c = AiCommandCapture();
      var finalizeCalls = 0;
      c.onFinalize = (_) => finalizeCalls++;
      c.finalizeNow();
      expect(finalizeCalls, 0);
      c.dispose();
    });

    test('start() after a prior completed capture clears the old buffer '
        '(no leakage between successive commands)', () {
      final c = AiCommandCapture(timeout: const Duration(seconds: 30));
      final delivered = <String>[];
      c.onFinalize = (text) => delivered.add(text);
      c.start('first command');
      c.finalizeNow();
      c.start('second command');
      c.finalizeNow();
      expect(delivered, ['first command', 'second command']);
      c.dispose();
    });
  });

  group('AiCommandCapture: inactivity timeout auto-finalize', () {
    test('auto-finalizes via the inactivity timer when no further feed() '
        'or finalizeNow() call arrives before the timeout elapses', () async {
      final c = AiCommandCapture(timeout: const Duration(milliseconds: 50));
      String? delivered;
      c.onFinalize = (text) => delivered = text;
      c.start('auto finalize me');
      expect(c.isCapturing, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(delivered, 'auto finalize me');
      expect(c.state, AiCaptureState.idle);
      c.dispose();
    });

    test('each feed() re-arms the inactivity timer, so capture survives '
        'past the original timeout as long as chunks keep arriving', () async {
      final c = AiCommandCapture(timeout: const Duration(milliseconds: 80));
      String? delivered;
      c.onFinalize = (text) => delivered = text;
      c.start('part one');
      // Feed again before the timer would have fired, twice, spanning
      // longer than a single timeout window in total.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      c.feed('part two');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      c.feed('part three');
      // Still capturing - neither feed() allowed the timer to fire.
      expect(c.isCapturing, isTrue);
      expect(delivered, isNull);
      // Now let it actually go silent and auto-finalize.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(delivered, 'part one part two part three');
      c.dispose();
    });

    test(
      'changing timeout mid-capture does not disrupt the timer already '
      'armed with the previous duration - it only affects the next '
      'arm (start/feed) - matching VoiceEngine.silenceTimeout semantics',
      () async {
        final c = AiCommandCapture(timeout: const Duration(milliseconds: 200));
        String? delivered;
        c.onFinalize = (text) => delivered = text;
        c.start('long timeout in flight');
        // Widen the timeout after the timer is already armed at 200ms.
        c.timeout = const Duration(seconds: 30);
        // The already-armed 200ms timer must still fire on schedule since
        // Timer captures its duration at creation time, not by reference.
        await Future<void>.delayed(const Duration(milliseconds: 280));
        expect(delivered, 'long timeout in flight');
        c.dispose();
      },
    );

    test('cancel() stops a pending inactivity timer from firing '
        'onFinalize afterwards', () async {
      final c = AiCommandCapture(timeout: const Duration(milliseconds: 50));
      var finalizeCalls = 0;
      c.onFinalize = (_) => finalizeCalls++;
      c.start('will be cancelled');
      c.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(finalizeCalls, 0);
      c.dispose();
    });

    test('dispose() cancels any pending inactivity timer', () async {
      final c = AiCommandCapture(timeout: const Duration(milliseconds: 50));
      var finalizeCalls = 0;
      c.onFinalize = (_) => finalizeCalls++;
      c.start('will be disposed');
      c.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(finalizeCalls, 0);
    });
  });
}
