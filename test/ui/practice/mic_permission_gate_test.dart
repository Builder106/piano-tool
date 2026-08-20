import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:piano_tool/ui/practice/mic_permission_gate.dart';
import 'package:piano_tool/ui/practice/stage_controller.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

Widget _harness(Future<bool> Function(Ref) grant) => ProviderScope(
      overrides: [audioGrantedProvider.overrideWith(grant)],
      child: MaterialApp(
        theme: PianoTheme.light(),
        home: const Scaffold(
          body: MicPermissionGate(child: Text('practice')),
        ),
      ),
    );

void main() {
  testWidgets('shows the child once the microphone is granted', (tester) async {
    await tester.pumpWidget(_harness((ref) async => true));
    await tester.pumpAndSettle();
    expect(find.text('practice'), findsOneWidget);
  });

  testWidgets('explains the problem and offers a retry when denied',
      (tester) async {
    await tester.pumpWidget(_harness((ref) async => false));
    await tester.pumpAndSettle();

    expect(find.text('practice'), findsNothing);
    expect(find.textContaining('microphone'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
  });

  testWidgets('surfaces a failure instead of hanging', (tester) async {
    await tester.pumpWidget(_harness((ref) async => throw Exception('no device')));
    await tester.pumpAndSettle();
    expect(find.textContaining('microphone'), findsWidgets);
  });

  testWidgets('shows progress while the request is outstanding', (tester) async {
    final completer = Completer<bool>();
    await tester.pumpWidget(_harness((ref) => completer.future));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('practice'), findsOneWidget);
  });

  testWidgets('a retry after a denial actually recovers', (tester) async {
    // The gate must not latch on its error state: a learner who grants the
    // permission from system settings and comes back has to get in.
    var attempt = 0;
    await tester.pumpWidget(_harness((ref) async => attempt++ > 0));
    await tester.pumpAndSettle();
    expect(find.text('practice'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
    await tester.pumpAndSettle();
    expect(find.text('practice'), findsOneWidget);
  });
}
