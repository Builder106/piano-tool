import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/services/midi_service.dart';
import 'package:piano_tool/services/midi_transport.dart';

import 'fake_midi_transport.dart';

const _usbPiano = MidiDevice(
  id: 'usb-1',
  name: 'Digital Piano',
  type: MidiDeviceType.usb,
);
const _blePiano = MidiDevice(
  id: 'ble-1',
  name: 'BLE Keys',
  type: MidiDeviceType.bluetooth,
);

void main() {
  group('MidiService', () {
    late FakeMidiTransport transport;
    late MidiService service;

    setUp(() {
      transport = FakeMidiTransport([_usbPiano, _blePiano]);
      service = MidiService(transport: transport);
    });

    tearDown(() {
      service.dispose();
    });

    test('lists no devices and opens nothing before a scan', () {
      expect(service.devices, isEmpty);
      expect(service.selectedDevice, isNull);
      expect(service.isConnected, isFalse);
      expect(transport.calls, isEmpty);
    });

    test('scanDevices lists what the transport finds', () async {
      await service.scanDevices();

      expect(transport.calls, ['scan', 'list']);
      expect(service.devices.map((d) => d.id), ['usb-1', 'ble-1']);
      expect(service.devices.map((d) => d.type), [
        MidiDeviceType.usb,
        MidiDeviceType.bluetooth,
      ]);
      expect(service.isScanning, isFalse);
    });

    test('a failed Bluetooth scan still lists cable devices', () async {
      transport
        ..inputs = [_usbPiano]
        ..scanError = const MidiUnavailableException('Bluetooth is off.');

      await service.scanDevices();

      expect(service.devices.single.id, 'usb-1');
      expect(service.error, 'Bluetooth is off.');
    });

    test(
      'connectDevice and disconnectDevice update connection state',
      () async {
        await service.scanDevices();
        await service.connectDevice('usb-1');

        expect(transport.connected, ['usb-1']);
        expect(service.isConnected, isTrue);
        expect(service.selectedDevice?.id, 'usb-1');
        expect(service.devices.where((d) => d.connected).single.id, 'usb-1');

        await service.disconnectDevice();
        expect(transport.connected, isEmpty);
        expect(service.isConnected, isFalse);
        expect(service.selectedDevice, isNull);
      },
    );

    test('connecting a second keyboard disconnects the first', () async {
      await service.scanDevices();
      await service.connectDevice('usb-1');
      await service.connectDevice('ble-1');

      expect(transport.connected, ['ble-1']);
      expect(service.selectedDevice?.id, 'ble-1');
    });

    test('an unplugged keyboard drops out of the list and selection', () async {
      await service.scanDevices();
      await service.connectDevice('usb-1');

      transport
        ..inputs = [_blePiano]
        ..changeSetup();
      await pumpEventQueue();

      expect(service.devices.single.id, 'ble-1');
      expect(service.selectedDevice, isNull);
    });

    test('every message from the transport reaches the pitch stream', () async {
      final events = <PitchEvent>[];
      final sub = service.pitchStream.listen(events.add);
      await service.scanDevices();
      await service.connectDevice('usb-1');

      for (final note in [60, 62, 64]) {
        transport
          ..play([0x90, note, 90])
          ..play([0x80, note, 0]);
      }
      // Active Sensing, which many keyboards send every 300 ms.
      transport.play([0xFE]);
      await pumpEventQueue();

      expect(events.map((e) => e.midiNote), [60, 62, 64]);
      expect(events.every((e) => e.confidence == 1.0), isTrue);
      expect(service.lastMessage?.isNoteOff, isTrue);

      await sub.cancel();
    });

    test(
      'decodes Note On bytes and emits PitchEvent with 1.0 confidence',
      () async {
        final events = <PitchEvent>[];
        final sub = service.pitchStream.listen(events.add);

        // Note On channel 0, note 60 (Middle C), velocity 100
        service.handleMidiBytes([0x90, 60, 100]);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events.length, 1);
        final ev = events.first;
        expect(ev.midiNote, 60);
        expect(ev.confidence, 1.0);
        expect(ev.frequency, closeTo(261.63, 0.1));
        expect(ev.volume, closeTo(100 / 127.0, 0.01));

        await sub.cancel();
      },
    );

    test(
      'treats Note On with velocity 0 as Note Off (does not emit PitchEvent)',
      () async {
        final events = <PitchEvent>[];
        final sub = service.pitchStream.listen(events.add);

        service.handleMidiBytes([0x90, 60, 0]);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
        expect(service.lastMessage?.isNoteOff, isTrue);

        await sub.cancel();
      },
    );

    test('simulateNotePress emits Note On', () async {
      final events = <PitchEvent>[];
      final sub = service.pitchStream.listen(events.add);

      service.simulateNotePress(64, velocity: 80);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events.length, 1);
      expect(events.first.midiNote, 64);

      await sub.cancel();
    });

    test('simulateNoteRelease records a Note Off and emits no pitch', () async {
      final events = <PitchEvent>[];
      final sub = service.pitchStream.listen(events.add);

      service.simulateNotePress(67);
      service.simulateNoteRelease(67);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events.map((e) => e.midiNote), [67]);
      expect(service.lastMessage?.isNoteOff, isTrue);
      expect(service.lastMessage?.midiNote, 67);

      await sub.cancel();
    });

    test('simulated presses play stage 1 through the pitch stream', () async {
      const scale = [60, 62, 64, 65, 67, 69, 71, 72];
      final events = <PitchEvent>[];
      final sub = service.pitchStream.listen(events.add);

      for (final note in scale) {
        service
          ..simulateNotePress(note)
          ..simulateNoteRelease(note);
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events.map((e) => e.midiNote), scale);

      await sub.cancel();
    });
  });
}
