import 'dart:typed_data';

/// Turns float audio frames from the browser into the 16-bit little-endian
/// mono PCM that [PitchDetector] reads.
///
/// A browser's audio graph runs at the device rate, usually 48 kHz, while the
/// detector assumes [targetRate]. YIN reads frequency as rate over period, so
/// 48 kHz samples read as 44.1 kHz come out about 1.5 semitones flat: C4 is
/// heard as B3. Frames are resampled with linear interpolation, and the read
/// position carries across frame boundaries so the output has no seams.
class PcmFrameConverter {
  PcmFrameConverter({required this.sourceRate, required this.targetRate})
    : assert(sourceRate > 0 && targetRate > 0),
      _step = sourceRate / targetRate;

  final double sourceRate;
  final int targetRate;
  final double _step;

  /// Read position of the next output sample, in source samples from the
  /// start of the next frame. -1 is the last sample of the previous frame.
  double _position = 0;
  double _previous = 0;

  Uint8List convert(final Float32List frame) {
    final n = frame.length;
    if (n == 0) return Uint8List(0);

    final out = ByteData(((n + 1) / _step).ceil() * 2 + 2);
    var count = 0;
    while (_position <= n - 1) {
      final i = _position.floor();
      final fraction = _position - i;
      final a = i < 0 ? _previous : frame[i];
      final b = i + 1 < n ? frame[i + 1] : a;
      final sample = (a + (b - a) * fraction).clamp(-1.0, 1.0);
      out.setInt16(count * 2, (sample * 32767).round(), Endian.little);
      count++;
      _position += _step;
    }
    _position -= n;
    _previous = frame[n - 1];
    return out.buffer.asUint8List(0, count * 2);
  }
}
