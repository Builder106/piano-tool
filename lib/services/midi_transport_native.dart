import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart' as fmc;
import 'package:flutter_midi_command_ble/flutter_midi_command_ble.dart';

import 'midi_service.dart';
import 'midi_transport.dart';

MidiTransport createMidiTransport() => NativeMidiTransport();

/// MIDI through flutter_midi_command: CoreMIDI on iOS and macOS, Android's
/// MIDI service, and Bluetooth LE through its universal_ble transport.
class NativeMidiTransport implements MidiTransport {
  static const Duration _scanWindow = Duration(seconds: 4);

  final StreamController<List<int>> _messages =
      StreamController<List<int>>.broadcast();
  final StreamController<void> _setupChanged =
      StreamController<void>.broadcast();
  final Map<String, fmc.MidiDevice> _known = {};
  fmc.MidiCommand? _midi;
  StreamSubscription<fmc.MidiPacket>? _packetSub;
  StreamSubscription<fmc.MidiSetupChange>? _setupSub;

  /// The plugin's BLE transport does not run on Linux.
  bool get _bleSupported => defaultTargetPlatform != TargetPlatform.linux;

  /// Opened on first use, so a session that never touches MIDI never asks
  /// for Bluetooth.
  fmc.MidiCommand get _command => _midi ??= _open();

  fmc.MidiCommand _open() {
    final midi = fmc.MidiCommand();
    // BLE has to be configured before the streams are read, or they leave
    // Bluetooth devices out.
    if (_bleSupported) midi.configureBleTransport(UniversalBleMidiTransport());
    _packetSub = midi.onMidiPacketReceived?.listen(
      (p) => _messages.add(p.data),
    );
    _setupSub = midi.onMidiSetupChanged?.listen((_) => _setupChanged.add(null));
    return midi;
  }

  @override
  Stream<List<int>> get messages => _messages.stream;

  @override
  Stream<void> get setupChanged => _setupChanged.stream;

  @override
  Future<List<MidiDevice>> listDevices() async {
    final devices = await _command.devices ?? const <fmc.MidiDevice>[];
    _known
      ..clear()
      ..addEntries(devices.map((d) => MapEntry(d.id, d)));
    return [
      for (final d in devices)
        MidiDevice(
          id: d.id,
          name: d.name,
          type: switch (d.type) {
            fmc.MidiDeviceType.ble => MidiDeviceType.bluetooth,
            fmc.MidiDeviceType.serial => MidiDeviceType.usb,
            _ => MidiDeviceType.other,
          },
          connected: d.connected,
        ),
    ];
  }

  @override
  Future<void> scanBluetooth() async {
    if (!_bleSupported) return;
    final midi = _command;
    await midi.startBluetooth();
    await midi.waitUntilBluetoothIsInitialized().timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
    final state = midi.bluetoothState;
    if (state != fmc.BluetoothState.poweredOn) {
      throw MidiUnavailableException(switch (state) {
        fmc.BluetoothState.poweredOff => 'Bluetooth is off.',
        fmc.BluetoothState.unauthorized =>
          'Piano Tool is not allowed to use Bluetooth.',
        fmc.BluetoothState.unsupported =>
          'This device has no Bluetooth LE support.',
        _ => 'Bluetooth is not ready.',
      });
    }
    await midi.startScanningForBluetoothDevices();
    await Future<void>.delayed(_scanWindow);
    midi.stopScanningForBluetoothDevices();
  }

  @override
  Future<void> connect(String id) async {
    final device = _known[id];
    if (device == null) return;
    await _command.connectToDevice(device);
  }

  @override
  Future<void> disconnect(String id) async {
    final device = _known[id];
    if (device == null) return;
    _command.disconnectDevice(device);
  }

  @override
  void dispose() {
    _packetSub?.cancel();
    _setupSub?.cancel();
    _messages.close();
    _setupChanged.close();
  }
}
