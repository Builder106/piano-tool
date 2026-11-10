import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keeps a phone on its side while a screen that needs the width is open, as
/// the music and the keyboard do. Several screens can hold the lock at once,
/// so one handing over to the next never lets the phone turn upright between
/// them. Larger screens are left alone.
abstract final class LandscapeLock {
  static int _holders = 0;

  static bool get _onPhone {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize.shortestSide / view.devicePixelRatio < 600;
  }

  /// Takes the lock. Returns whether it was taken: pass that to [release].
  static bool acquire() {
    if (!_onPhone) return false;
    if (_holders++ == 0) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    return true;
  }

  static void release() {
    if (_holders > 0 && --_holders == 0) {
      SystemChrome.setPreferredOrientations(const []);
    }
  }
}
