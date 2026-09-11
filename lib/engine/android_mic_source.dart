/// Android microphone source: streams 16kHz PCM16 chunks from the
/// native AudioRecord (VOICE_RECOGNITION source) over an EventChannel.
library;

import 'dart:async';

import 'package:flutter/services.dart';

import 'mic_source.dart';

class AndroidMicSource implements MicAudioSource {
  static const MethodChannel _system = MethodChannel('bhasha/system');
  static const EventChannel _mic = EventChannel('bhasha/mic');

  StreamController<List<int>>? _controller;
  StreamSubscription<dynamic>? _nativeSubscription;

  @override
  Future<bool> hasPermission() async {
    try {
      final granted = await _system.invokeMethod<bool>('hasMicPermission');
      if (granted == true) return true;
      // The IME cannot display a runtime permission dialog itself. The native
      // bridge opens the launcher activity when permission is missing.
      final after = await _system.invokeMethod<bool>('requestMicPermission');
      return after == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Stream<List<int>>> start() async {
    await stop();
    final controller = StreamController<List<int>>.broadcast();
    _controller = controller;

    // This subscription installs the native EventChannel sink before the
    // caller receives the stream and subscribes to it.
    _nativeSubscription = _mic.receiveBroadcastStream().listen((event) {
      if (event is List) controller.add(event.cast<int>());
    }, onError: controller.addError);

    controller.onListen = () async {
      final ok = await _system.invokeMethod<bool>('startMic');
      if (ok != true && !controller.isClosed) {
        controller.addError(StateError('Microphone unavailable'));
      }
    };
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    try {
      await _system.invokeMethod('stopMic');
    } catch (_) {}
    await _nativeSubscription?.cancel();
    _nativeSubscription = null;
    await _controller?.close();
    _controller = null;
  }
}
