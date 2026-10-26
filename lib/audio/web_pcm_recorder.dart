import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'pcm_frame_converter.dart';
import 'pitch_detector.dart';

PcmRecorder createPcmRecorder() => WebPcmRecorder();

/// Posts the first input channel to the main thread in 1024-frame batches.
/// The node's channel count is fixed at 1, so the browser has already mixed
/// a stereo microphone down to mono.
const String _workletSource = '''
class PianoToolPcmCapture extends AudioWorkletProcessor {
  constructor() {
    super();
    this.batch = new Float32Array(1024);
    this.filled = 0;
  }
  process(inputs) {
    const channel = inputs[0] && inputs[0][0];
    if (!channel) return true;
    let read = 0;
    while (read < channel.length) {
      const take = Math.min(channel.length - read, this.batch.length - this.filled);
      this.batch.set(channel.subarray(read, read + take), this.filled);
      this.filled += take;
      read += take;
      if (this.filled === this.batch.length) {
        this.port.postMessage(this.batch, [this.batch.buffer]);
        this.batch = new Float32Array(1024);
        this.filled = 0;
      }
    }
    return true;
  }
}
registerProcessor('piano-tool-pcm-capture', PianoToolPcmCapture);
''';

/// Microphone capture for the web build. flutter_sound's web recorder does
/// not deliver usable 16-bit PCM at the requested rate, so this opens the
/// microphone with getUserMedia and taps it with an AudioWorklet.
class WebPcmRecorder implements PcmRecorder {
  web.MediaStream? _stream;
  web.AudioContext? _context;
  web.AudioWorkletNode? _node;
  web.MediaStreamAudioSourceNode? _source;
  JSFunction? _resumeOnGesture;

  @override
  Future<void> open() async {}

  @override
  Future<void> start({
    required final StreamSink<Uint8List> sink,
    required final int sampleRate,
  }) async {
    // A piano is not speech: the browser's voice processing would treat
    // sustained tones as noise or echo and pull them down.
    final constraints = web.MediaStreamConstraints(
      audio: {
        'channelCount': 1,
        'echoCancellation': false,
        'noiseSuppression': false,
        'autoGainControl': false,
      }.jsify()!,
    );
    final stream = await web.window.navigator.mediaDevices
        .getUserMedia(constraints)
        .toDart;
    _stream = stream;

    final context = web.AudioContext();
    _context = context;
    final url = web.URL.createObjectURL(
      web.Blob(
        [_workletSource.toJS].toJS,
        web.BlobPropertyBag(type: 'text/javascript'),
      ),
    );
    try {
      await context.audioWorklet.addModule(url).toDart;
    } finally {
      web.URL.revokeObjectURL(url);
    }

    final converter = PcmFrameConverter(
      sourceRate: context.sampleRate,
      targetRate: sampleRate,
    );
    final node = web.AudioWorkletNode(
      context,
      'piano-tool-pcm-capture',
      web.AudioWorkletNodeOptions(
        numberOfInputs: 1,
        numberOfOutputs: 1,
        channelCount: 1,
        channelCountMode: 'explicit',
      ),
    );
    node.port.onmessage = (web.MessageEvent event) {
      final frame = (event.data as JSFloat32Array).toDart;
      sink.add(converter.convert(frame));
    }.toJS;
    _node = node;

    final source = context.createMediaStreamSource(stream);
    source.connect(node);
    // The node writes silence; the connection only keeps the graph pulling.
    node.connect(context.destination);
    _source = source;

    await _resume(context);
    debugPrint('WebPcmRecorder: ${context.sampleRate} Hz to $sampleRate Hz');
  }

  /// Browsers may keep a context suspended until the page gets a gesture.
  /// Practice always starts with a press of Play, so the first one resumes it.
  Future<void> _resume(final web.AudioContext context) async {
    await context.resume().toDart;
    if (context.state == 'running') return;
    final listener = (web.Event _) {
      unawaited(context.resume().toDart);
      _removeGestureListener();
    }.toJS;
    _resumeOnGesture = listener;
    web.document.addEventListener('pointerdown', listener);
    web.document.addEventListener('keydown', listener);
  }

  void _removeGestureListener() {
    final listener = _resumeOnGesture;
    if (listener == null) return;
    web.document.removeEventListener('pointerdown', listener);
    web.document.removeEventListener('keydown', listener);
    _resumeOnGesture = null;
  }

  @override
  Future<void> stop() async {
    _removeGestureListener();
    _source?.disconnect();
    _source = null;
    final node = _node;
    if (node != null) {
      node.port.onmessage = null;
      node.disconnect();
      node.port.close();
    }
    _node = null;
    final tracks = _stream?.getTracks().toDart ?? <web.MediaStreamTrack>[];
    for (final track in tracks) {
      track.stop();
    }
    _stream = null;
    final context = _context;
    _context = null;
    if (context != null && context.state != 'closed') {
      await context.close().toDart;
    }
  }

  @override
  Future<void> close() => stop();
}
