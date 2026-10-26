import 'midi_service.dart';

/// Where MIDI bytes come from: CoreMIDI, Android MIDI and BLE on devices, the
/// Web MIDI API in a browser. [MidiService] owns the device list and decoding;
/// a transport only finds inputs and forwards what they send.
abstract interface class MidiTransport {
  /// Every MIDI input the platform can see now, including Bluetooth devices
  /// found by the last [scanBluetooth].
  Future<List<MidiDevice>> listDevices();

  /// Looks for Bluetooth LE MIDI devices for a short window. Throws a
  /// [MidiUnavailableException] when Bluetooth cannot be used.
  Future<void> scanBluetooth();

  Future<void> connect(String id);

  Future<void> disconnect(String id);

  /// One complete MIDI message per event, from any connected input.
  Stream<List<int>> get messages;

  /// Fires when inputs appear, disappear or change connection state.
  Stream<void> get setupChanged;

  void dispose();
}

/// MIDI or Bluetooth cannot be used here, with a reason the user can act on.
class MidiUnavailableException implements Exception {
  const MidiUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}
