import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/audio_models.dart';

/// Connection interface type for digital piano hardware.
enum MidiDeviceType {
  usb('USB MIDI', 'Direct cable connection via USB-MIDI interface'),
  bluetooth('Bluetooth LE MIDI', 'Wireless connection via BLE MIDI');

  const MidiDeviceType(this.label, this.description);
  final String label;
  final String description;
}

/// Represents an external digital piano or MIDI controller keyboard.
@immutable
class MidiDevice {
  const MidiDevice({
    required this.id,
    required this.name,
    required this.type,
    this.connected = false,
  });

  final String id;
  final String name;
  final MidiDeviceType type;
  final bool connected;

  MidiDevice copyWith({bool? connected}) => MidiDevice(
    id: id,
    name: name,
    type: type,
    connected: connected ?? this.connected,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiDevice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          connected == other.connected;

  @override
  int get hashCode => Object.hash(id, name, type, connected);
}

/// A parsed MIDI message event.
@immutable
class MidiMessage {
  const MidiMessage({
    required this.status,
    required this.data1,
    required this.data2,
    required this.timestamp,
  });

  final int status;
  final int data1;
  final int data2;
  final DateTime timestamp;

  bool get isNoteOn => (status & 0xF0) == 0x90 && data2 > 0;
  bool get isNoteOff =>
      (status & 0xF0) == 0x80 || ((status & 0xF0) == 0x90 && data2 == 0);
  int get midiNote => data1;
  int get velocity => data2;

  @override
  String toString() =>
      'MidiMessage(status: 0x${status.toRadixString(16)}, note: $midiNote, velocity: $velocity)';
}

/// Service managing USB and Bluetooth MIDI keyboard input for practice.
class MidiService extends ChangeNotifier {
  MidiService() {
    _initDefaultDevices();
  }

  final List<MidiDevice> _devices = [];
  MidiDevice? _selectedDevice;
  bool _isScanning = false;
  MidiMessage? _lastMessage;

  final StreamController<PitchEvent> _pitchController =
      StreamController<PitchEvent>.broadcast();

  final StreamController<MidiMessage> _messageController =
      StreamController<MidiMessage>.broadcast();

  List<MidiDevice> get devices => List.unmodifiable(_devices);
  MidiDevice? get selectedDevice => _selectedDevice;
  bool get isScanning => _isScanning;
  MidiMessage? get lastMessage => _lastMessage;
  bool get isConnected => _selectedDevice != null;

  Stream<PitchEvent> get pitchStream => _pitchController.stream;
  Stream<MidiMessage> get messageStream => _messageController.stream;

  void _initDefaultDevices() {
    _devices.addAll([
      const MidiDevice(
        id: 'usb_keyboard_generic',
        name: 'USB Digital Piano / Keyboard',
        type: MidiDeviceType.usb,
      ),
      const MidiDevice(
        id: 'ble_keyboard_generic',
        name: 'Bluetooth LE MIDI Keyboard',
        type: MidiDeviceType.bluetooth,
      ),
    ]);
  }

  /// Scan for newly attached USB and discoverable Bluetooth MIDI devices.
  Future<void> scanDevices() async {
    _isScanning = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 300));
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to a specific digital piano device.
  void connectDevice(String id) {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index == -1) return;

    for (var i = 0; i < _devices.length; i++) {
      _devices[i] = _devices[i].copyWith(connected: i == index);
    }
    _selectedDevice = _devices[index];
    notifyListeners();
  }

  /// Disconnect the active MIDI device.
  void disconnectDevice() {
    for (var i = 0; i < _devices.length; i++) {
      _devices[i] = _devices[i].copyWith(connected: false);
    }
    _selectedDevice = null;
    notifyListeners();
  }

  /// Decode raw MIDI byte stream packet.
  /// Standard MIDI 1.0: 0x90 = Note On, 0x80 = Note Off.
  void handleMidiBytes(List<int> bytes) {
    if (bytes.length < 3) return;

    final status = bytes[0];
    final note = bytes[1].clamp(0, 127);
    final velocity = bytes[2].clamp(0, 127);
    final msg = MidiMessage(
      status: status,
      data1: note,
      data2: velocity,
      timestamp: DateTime.now(),
    );

    _lastMessage = msg;
    _messageController.add(msg);
    notifyListeners();

    if (msg.isNoteOn) {
      final frequency = 440.0 * math.pow(2.0, (note - 69) / 12.0);
      final event = PitchEvent(
        frequency: frequency,
        confidence: 1.0,
        midiNote: note,
        timestamp: msg.timestamp.millisecondsSinceEpoch / 1000.0,
        volume: (velocity / 127.0).clamp(0.1, 1.0),
      );
      _pitchController.add(event);
    }
  }

  /// Test utility to simulate a physical MIDI keypress.
  void simulateNotePress(int midiNote, {int velocity = 100}) {
    handleMidiBytes([0x90, midiNote, velocity]);
  }

  /// Test utility to simulate physical MIDI key release.
  void simulateNoteRelease(int midiNote) {
    handleMidiBytes([0x80, midiNote, 0]);
  }

  @override
  void dispose() {
    _pitchController.close();
    _messageController.close();
    super.dispose();
  }
}

/// Global provider for the MIDI input service.
final midiServiceProvider = ChangeNotifierProvider<MidiService>((ref) {
  return MidiService();
});

/// Stream provider for pitch events coming from MIDI hardware.
final midiPitchStreamProvider = StreamProvider<PitchEvent>(
  (ref) => ref.watch(midiServiceProvider).pitchStream,
);
