import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

/// The two things a new piece can be made from that need the device: an audio
/// file the learner picks, and a recording of them playing. Kept behind an
/// interface so the screen can be tested without a plugin.
abstract interface class ImportInputs {
  /// Asks for an audio file. Null when none was chosen.
  Future<File?> pickAudioFile();

  /// Starts recording. False when the microphone is not allowed.
  Future<bool> startRecording();

  /// Stops and returns the recording as a WAV file's bytes.
  Future<Uint8List?> stopRecording();

  void dispose();
}

class DeviceImportInputs implements ImportInputs {
  final _recorder = AudioRecorder();

  @override
  Future<File?> pickAudioFile() async {
    final picked = await FilePicker.pickFile(type: FileType.audio);
    final path = picked?.path;
    return path == null ? null : File(path);
  }

  @override
  Future<bool> startRecording() async {
    if (!await _recorder.hasPermission()) return false;
    final path =
        '${Directory.systemTemp.path}/piano_tool_recording_'
        '${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: path,
    );
    return true;
  }

  @override
  Future<Uint8List?> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    final file = File(path);
    final bytes = await file.readAsBytes();
    await file.delete();
    return bytes;
  }

  @override
  void dispose() => _recorder.dispose();
}

final importInputsProvider = Provider.autoDispose<ImportInputs>((ref) {
  final inputs = DeviceImportInputs();
  ref.onDispose(inputs.dispose);
  return inputs;
});
