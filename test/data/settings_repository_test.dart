import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:piano_tool/data/settings_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsRepository', () {
    test('returns default settings when preferences are empty', () async {
      final repo = SettingsRepository();
      final settings = await repo.read();

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.defaultPlaybackSpeed, 1.0);
      expect(settings.toleranceLevel, ToleranceLevel.normal);
      expect(settings.minVolumeThreshold, 0.1);
      expect(settings.referenceFrequency, 440.0);
      expect(settings.customApiBaseUrl, isNull);
    });

    test('saves and reads updated theme mode', () async {
      final repo = SettingsRepository();
      await repo.updateThemeMode(ThemeMode.dark);
      var settings = await repo.read();
      expect(settings.themeMode, ThemeMode.dark);

      await repo.updateThemeMode(ThemeMode.light);
      settings = await repo.read();
      expect(settings.themeMode, ThemeMode.light);
    });

    test('saves and reads updated playback speed', () async {
      final repo = SettingsRepository();
      await repo.updateSpeed(0.75);
      final settings = await repo.read();
      expect(settings.defaultPlaybackSpeed, 0.75);
    });

    test('saves and reads updated tolerance level', () async {
      final repo = SettingsRepository();
      await repo.updateTolerance(ToleranceLevel.strict);
      var settings = await repo.read();
      expect(settings.toleranceLevel, ToleranceLevel.strict);

      await repo.updateTolerance(ToleranceLevel.relaxed);
      settings = await repo.read();
      expect(settings.toleranceLevel, ToleranceLevel.relaxed);
    });

    test('saves and reads custom API base URL, trimming whitespace', () async {
      final repo = SettingsRepository();
      const customUrl = '  https://api.pianotool.dev/v1  ';
      final updated = const AppSettings().copyWith(customApiBaseUrl: customUrl);
      await repo.save(updated);

      final settings = await repo.read();
      expect(settings.customApiBaseUrl, 'https://api.pianotool.dev/v1');
    });

    test('removes custom API URL when cleared', () async {
      final repo = SettingsRepository();
      await repo.save(
        const AppSettings().copyWith(customApiBaseUrl: 'https://example.com'),
      );
      var settings = await repo.read();
      expect(settings.customApiBaseUrl, 'https://example.com');

      await repo.save(
        const AppSettings().copyWith(clearCustomApiBaseUrl: true),
      );
      settings = await repo.read();
      expect(settings.customApiBaseUrl, isNull);
    });
  });

  group('AppSettings configuration mappings', () {
    test('maps tolerance levels correctly to StageEngineConfig', () {
      const relaxed = AppSettings(
        toleranceLevel: ToleranceLevel.relaxed,
        defaultPlaybackSpeed: 0.8,
      );
      final relaxedConfig = relaxed.toStageEngineConfig();
      expect(relaxedConfig.perfectWindow, 0.15);
      expect(relaxedConfig.goodWindow, 0.30);
      expect(relaxedConfig.okayWindow, 0.45);
      expect(relaxedConfig.missWindow, 0.70);
      expect(relaxedConfig.playbackSpeed, 0.8);

      const normal = AppSettings(
        toleranceLevel: ToleranceLevel.normal,
        defaultPlaybackSpeed: 1.0,
      );
      final normalConfig = normal.toStageEngineConfig();
      expect(normalConfig.perfectWindow, 0.10);
      expect(normalConfig.goodWindow, 0.20);
      expect(normalConfig.okayWindow, 0.30);
      expect(normalConfig.missWindow, 0.50);
      expect(normalConfig.playbackSpeed, 1.0);

      const strict = AppSettings(
        toleranceLevel: ToleranceLevel.strict,
        defaultPlaybackSpeed: 1.5,
      );
      final strictConfig = strict.toStageEngineConfig();
      expect(strictConfig.perfectWindow, 0.06);
      expect(strictConfig.goodWindow, 0.12);
      expect(strictConfig.okayWindow, 0.20);
      expect(strictConfig.missWindow, 0.35);
      expect(strictConfig.playbackSpeed, 1.5);
    });

    test('maps audio configuration correctly', () {
      const settings = AppSettings(
        minVolumeThreshold: 0.15,
        referenceFrequency: 442.0,
      );
      final audioConfig = settings.toAudioEngineConfig();
      expect(audioConfig.minVolumeThreshold, 0.15);
      expect(audioConfig.referenceFrequency, 442.0);
    });
  });
}
