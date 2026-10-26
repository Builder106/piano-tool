import 'dart:async';

import 'package:piano_tool/services/midi_service.dart';
import 'package:piano_tool/services/midi_transport.dart';

/// Stands in for CoreMIDI, Android MIDI or Web MIDI: a list of inputs that
/// tests can change, and a byte stream tests can play into.
class FakeMidiTransport implements MidiTransport {
  FakeMidiTransport(this.inputs);

  List<MidiDevice> inputs;
  Object? scanError;
  final List<String> connected = [];
  final List<String> calls = [];
  final StreamController<List<int>> _messages = StreamController.broadcast();
  final StreamController<void> _setup = StreamController.broadcast();

  void play(List<int> bytes) => _messages.add(bytes);

  void changeSetup() => _setup.add(null);

  @override
  Stream<List<int>> get messages => _messages.stream;

  @override
  Stream<void> get setupChanged => _setup.stream;

  @override
  Future<List<MidiDevice>> listDevices() async {
    calls.add('list');
    return inputs;
  }

  @override
  Future<void> scanBluetooth() async {
    calls.add('scan');
    final error = scanError;
    if (error != null) throw error;
  }

  @override
  Future<void> connect(String id) async {
    calls.add('connect $id');
    connected.add(id);
  }

  @override
  Future<void> disconnect(String id) async {
    calls.add('disconnect $id');
    connected.remove(id);
  }

  @override
  void dispose() {
    _messages.close();
    _setup.close();
  }
}
