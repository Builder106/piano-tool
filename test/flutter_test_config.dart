import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Flutter test harnesses do not load fonts declared in pubspec.yaml, so text
/// renders as tofu boxes unless the bytes are loaded explicitly. Golden images
/// would otherwise bake in missing glyphs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  goldenFileComparator = TolerantGoldenFileComparator(
    (goldenFileComparator as LocalFileComparator).basedir,
    tolerance: 0.01,
  );
  await _load('CormorantGaramond', 'assets/fonts/CormorantGaramond.ttf');
  await _load('IBMPlexSans', 'assets/fonts/IBMPlexSans.ttf');
  await _load('Bravura', 'assets/fonts/Bravura.otf');
  // `flutter test` ships no icon font either, so every IconData renders as a
  // tofu box in a golden unless the SDK's own copy is loaded here.
  await _loadFile('MaterialIcons', _materialIconsPath);
  await testMain();
}

/// Custom golden file comparator that allows a fractional pixel difference
/// threshold (default 1%) to accommodate sub-pixel font rasterization
/// across Linux runner versions.
class TolerantGoldenFileComparator extends LocalFileComparator {
  TolerantGoldenFileComparator(
    super.testFile, {
    this.tolerance = 0.01,
  });

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    final bool passed = result.passed || result.diffPercent <= tolerance;
    if (passed) {
      result.dispose();
      return true;
    }

    final String error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw TestFailure(error);
  }
}

Future<void> _load(String family, String path) async {
  final data = await rootBundle.load(path);
  await ui.loadFontFromList(data.buffer.asUint8List(), fontFamily: family);
}

/// The icon font lives in the Flutter SDK rather than in this package's
/// assets, so it is read from disk rather than through the asset bundle.
/// FLUTTER_ROOT is set by `flutter test`; the walk up from the running Dart
/// executable covers a runner that does not set it.
String? get _materialIconsPath {
  final fromEnv = Platform.environment['FLUTTER_ROOT'];
  final roots = <String>[
    if (fromEnv != null) fromEnv,
    ..._ancestorsOf(Platform.resolvedExecutable),
  ];
  for (final root in roots) {
    final candidate = p.join(root, 'bin', 'cache', 'artifacts',
        'material_fonts', 'MaterialIcons-Regular.otf');
    if (File(candidate).existsSync()) return candidate;
  }
  return null;
}

Iterable<String> _ancestorsOf(String path) sync* {
  var dir = p.dirname(path);
  while (dir != p.dirname(dir)) {
    yield dir;
    dir = p.dirname(dir);
  }
}

Future<void> _loadFile(String family, String? path) async {
  if (path == null) return;
  final bytes = await File(path).readAsBytes();
  await ui.loadFontFromList(bytes, fontFamily: family);
}
