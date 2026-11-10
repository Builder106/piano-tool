import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/brand/orientation.dart';
import 'package:piano_tool/brand/scale.dart';

void main() {
  final calls = <List<dynamic>>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemChrome.setPreferredOrientations') {
            calls.add(call.arguments as List<dynamic>);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('a phone is held on its side until the last screen lets go', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 890);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final first = LandscapeLock.acquire();
    final second = LandscapeLock.acquire();
    expect([first, second], [true, true]);
    expect(calls, hasLength(1), reason: 'locked once, not per screen');
    expect(calls.single, [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
    ]);

    LandscapeLock.release();
    expect(calls, hasLength(1), reason: 'one screen still needs it');
    LandscapeLock.release();
    expect(calls, hasLength(2));
    expect(calls.last, isEmpty, reason: 'back to the device default');
  });

  testWidgets('a large screen is left alone', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    expect(LandscapeLock.acquire(), isFalse);
    expect(calls, isEmpty);
  });

  testWidgets('type scales with the smaller side of the window', (
    tester,
  ) async {
    Future<double> unit(Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      late double u;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              u = unitOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return u;
    }

    addTearDown(tester.view.reset);
    expect(await unit(const Size(1280, 720)), 1.0);
    expect(await unit(const Size(411, 890)), 0.7, reason: 'tall phone');
    expect(await unit(const Size(890, 411)), 0.7, reason: 'phone on its side');
    expect(await unit(const Size(2560, 1440)), 1.25, reason: 'large desktop');
  });
}
