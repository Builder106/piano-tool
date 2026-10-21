import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/audio_models.dart';
import 'package:piano_tool/services/midi_service.dart';

void main() {
  group('MidiService', () {
    late MidiService service;

    setUp(() {
      service = MidiService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initializes with default USB and Bluetooth device options', () {
      expect(service.devices.length, greaterThanOrEqualTo(2));
      expect(service.selectedDevice, isNull);
      expect(service.isConnected, isFalse);
    });

    test('connectDevice and disconnectDevice update connection state', () {
      final devId = service.devices.first.id;
      service.connectDevice(devId);

      expect(service.isConnected, isTrue);
      expect(service.selectedDevice?.id, devId);

      service.disconnectDevice();
      expect(service.isConnected, isFalse);
      expect(service.selectedDevice, isNull);
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
  });
}
