import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'midi_service.dart';
import 'midi_transport.dart';

MidiTransport createMidiTransport() => WebMidiTransport();

/// MIDI through the browser's Web MIDI API. The browser lists every input the
/// operating system knows, USB or already-paired Bluetooth, without saying
/// which, so every input is [MidiDeviceType.other].
class WebMidiTransport implements MidiTransport {
  final StreamController<List<int>> _messages =
      StreamController<List<int>>.broadcast();
  final StreamController<void> _setupChanged =
      StreamController<void>.broadcast();
  final Map<String, web.MIDIInput> _inputs = {};
  final Set<String> _open = {};
  web.MIDIAccess? _access;

  @override
  Stream<List<int>> get messages => _messages.stream;

  @override
  Stream<void> get setupChanged => _setupChanged.stream;

  /// Asked for on first use, so the browser prompts only when the player
  /// looks for a keyboard.
  Future<web.MIDIAccess> _requestAccess() async {
    final existing = _access;
    if (existing != null) return existing;
    if (!web.window.navigator.has('requestMIDIAccess')) {
      throw const MidiUnavailableException(
        'This browser has no Web MIDI. Use Chrome, Edge or Firefox.',
      );
    }
    final web.MIDIAccess access;
    try {
      access = await web.window.navigator.requestMIDIAccess().toDart;
    } catch (_) {
      throw const MidiUnavailableException(
        'The browser did not allow access to MIDI devices.',
      );
    }
    access.onstatechange = (web.Event _) {
      _setupChanged.add(null);
    }.toJS;
    return _access = access;
  }

  @override
  Future<List<MidiDevice>> listDevices() async {
    final access = await _requestAccess();
    _inputs.clear();
    // MIDIInputMap is a JS maplike, which package:web leaves without members.
    access.inputs.callMethod(
      'forEach'.toJS,
      (web.MIDIInput input) {
        _inputs[input.id] = input;
      }.toJS,
    );
    return [
      for (final input in _inputs.values)
        if (input.state == 'connected')
          MidiDevice(
            id: input.id,
            name: input.name ?? 'MIDI input',
            type: MidiDeviceType.other,
            connected: _open.contains(input.id),
          ),
    ];
  }

  @override
  Future<void> scanBluetooth() async {
    // A browser cannot pair Bluetooth MIDI. A keyboard paired in the system
    // settings appears in [listDevices] like any other input.
  }

  @override
  Future<void> connect(String id) async {
    final input = _inputs[id];
    if (input == null) return;
    input.onmidimessage = (web.MIDIMessageEvent event) {
      final data = event.data?.toDart;
      if (data != null) _messages.add(data);
    }.toJS;
    await input.open().toDart;
    _open.add(id);
  }

  @override
  Future<void> disconnect(String id) async {
    final input = _inputs[id];
    _open.remove(id);
    if (input == null) return;
    input.onmidimessage = null;
    await input.close().toDart;
  }

  @override
  void dispose() {
    for (final id in _open) {
      _inputs[id]?.onmidimessage = null;
    }
    _access?.onstatechange = null;
    _messages.close();
    _setupChanged.close();
  }
}
