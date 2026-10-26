import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/audio_models.dart';
import 'midi_transport.dart';
import 'midi_transport_native.dart'
    if (dart.library.js_interop) 'midi_transport_web.dart';

/// Connection interface type for digital piano hardware.
enum MidiDeviceType {
  usb('USB MIDI', 'Direct cable connection via USB-MIDI interface'),
  bluetooth('Bluetooth LE MIDI', 'Wireless connection via BLE MIDI'),
  other('MIDI input', 'A MIDI input the system or browser provides');

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
  MidiService({MidiTransport? transport})
    : _transport = transport ?? createMidiTransport() {
    _messageSub = _transport.messages.listen(handleMidiBytes);
    _setupSub = _transport.setupChanged.listen((_) {
      if (_scanned) unawaited(_refresh());
    });
  }

  final MidiTransport _transport;
  late final StreamSubscription<List<int>> _messageSub;
  late final StreamSubscription<void> _setupSub;

  final List<MidiDevice> _devices = [];
  MidiDevice? _selectedDevice;
  bool _isScanning = false;
  bool _scanned = false;
  String? _error;
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

  /// Why the last scan or connection failed, worded for the player.
  String? get error => _error;

  Stream<PitchEvent> get pitchStream => _pitchController.stream;
  Stream<MidiMessage> get messageStream => _messageController.stream;

  /// Lists attached MIDI inputs, after a short Bluetooth LE scan where the
  /// platform has one. Nothing is opened before the first scan, so the app
  /// never asks for MIDI or Bluetooth access until the player looks for a
  /// keyboard.
  Future<void> scanDevices() async {
    if (_isScanning) return;
    _isScanning = true;
    _error = null;
    notifyListeners();

    try {
      await _transport.scanBluetooth();
    } on MidiUnavailableException catch (e) {
      // A cable keyboard still works with Bluetooth off.
      _error = e.message;
    } catch (e) {
      debugPrint('MidiService: Bluetooth scan failed: $e');
      _error = 'The Bluetooth scan failed.';
    }
    await _refresh();
    _scanned = true;
    _isScanning = false;
    notifyListeners();
  }

  Future<void> _refresh() async {
    try {
      final found = await _transport.listDevices();
      final selectedId = _selectedDevice?.id;
      _devices
        ..clear()
        ..addAll(found.map((d) => d.copyWith(connected: d.id == selectedId)));
      // An unplugged keyboard is no longer selected.
      if (selectedId != null && !found.any((d) => d.id == selectedId)) {
        _selectedDevice = null;
      }
    } on MidiUnavailableException catch (e) {
      _error = e.message;
    } catch (e) {
      debugPrint('MidiService: listing MIDI devices failed: $e');
      _error = 'MIDI devices could not be listed.';
    }
    notifyListeners();
  }

  /// Connect to a specific digital piano device. Practice reads one keyboard,
  /// so any other connected device is disconnected first.
  Future<void> connectDevice(String id) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index == -1) return;

    await disconnectDevice();
    try {
      await _transport.connect(id);
    } catch (e) {
      debugPrint('MidiService: connecting $id failed: $e');
      _error = 'Could not connect to ${_devices[index].name}.';
      notifyListeners();
      return;
    }
    _error = null;
    for (var i = 0; i < _devices.length; i++) {
      _devices[i] = _devices[i].copyWith(connected: i == index);
    }
    _selectedDevice = _devices[index];
    notifyListeners();
  }

  /// Disconnect the active MIDI device.
  Future<void> disconnectDevice() async {
    final selected = _selectedDevice;
    for (var i = 0; i < _devices.length; i++) {
      _devices[i] = _devices[i].copyWith(connected: false);
    }
    _selectedDevice = null;
    notifyListeners();
    if (selected == null) return;
    try {
      await _transport.disconnect(selected.id);
    } catch (e) {
      debugPrint('MidiService: disconnecting ${selected.id} failed: $e');
    }
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
    _messageSub.cancel();
    _setupSub.cancel();
    _transport.dispose();
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
