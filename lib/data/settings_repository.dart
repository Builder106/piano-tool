import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/audio_models.dart';
import '../models/engine_models.dart';

/// Preset accuracy tolerance windows for practice scoring.
enum ToleranceLevel {
  relaxed(
    label: 'Relaxed',
    description: 'Notes count even when they land a little early or late',
    perfectWindow: 0.15,
    goodWindow: 0.30,
    okayWindow: 0.45,
    missWindow: 0.70,
  ),
  normal(
    label: 'Normal',
    description: 'Notes need to land close to the beat',
    perfectWindow: 0.10,
    goodWindow: 0.20,
    okayWindow: 0.30,
    missWindow: 0.50,
  ),
  strict(
    label: 'Strict',
    description: 'Notes need to land right on the beat',
    perfectWindow: 0.06,
    goodWindow: 0.12,
    okayWindow: 0.20,
    missWindow: 0.35,
  );

  const ToleranceLevel({
    required this.label,
    required this.description,
    required this.perfectWindow,
    required this.goodWindow,
    required this.okayWindow,
    required this.missWindow,
  });

  final String label;
  final String description;
  final double perfectWindow;
  final double goodWindow;
  final double okayWindow;
  final double missWindow;
}

/// Available audio and hardware input sources for practice.
enum PracticeInputSource {
  microphone('Microphone', 'Hears your piano through the microphone'),
  midi('Digital piano', 'Reads a digital piano over USB or Bluetooth'),
  both('Both', 'Listens and reads a digital piano at the same time');

  const PracticeInputSource(this.label, this.description);
  final String label;
  final String description;
}

/// Immutable app settings model.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.defaultPlaybackSpeed = 1.0,
    this.toleranceLevel = ToleranceLevel.normal,
    this.minVolumeThreshold = 0.1,
    this.referenceFrequency = 440.0,
    this.customApiBaseUrl,
    this.inputSource = PracticeInputSource.both,
    this.inputConfigured = true,
  });

  final ThemeMode themeMode;
  final double defaultPlaybackSpeed;
  final ToleranceLevel toleranceLevel;
  final double minVolumeThreshold;
  final double referenceFrequency;
  final String? customApiBaseUrl;
  final PracticeInputSource inputSource;
  final bool inputConfigured;

  StageEngineConfig toStageEngineConfig() => StageEngineConfig(
    perfectWindow: toleranceLevel.perfectWindow,
    goodWindow: toleranceLevel.goodWindow,
    okayWindow: toleranceLevel.okayWindow,
    missWindow: toleranceLevel.missWindow,
    playbackSpeed: defaultPlaybackSpeed,
  );

  AudioEngineConfig toAudioEngineConfig() => AudioEngineConfig(
    minVolumeThreshold: minVolumeThreshold,
    referenceFrequency: referenceFrequency,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? defaultPlaybackSpeed,
    ToleranceLevel? toleranceLevel,
    double? minVolumeThreshold,
    double? referenceFrequency,
    String? customApiBaseUrl,
    PracticeInputSource? inputSource,
    bool? inputConfigured,
    bool clearCustomApiBaseUrl = false,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
    toleranceLevel: toleranceLevel ?? this.toleranceLevel,
    minVolumeThreshold: minVolumeThreshold ?? this.minVolumeThreshold,
    referenceFrequency: referenceFrequency ?? this.referenceFrequency,
    customApiBaseUrl: clearCustomApiBaseUrl
        ? null
        : (customApiBaseUrl ?? this.customApiBaseUrl),
    inputSource: inputSource ?? this.inputSource,
    inputConfigured: inputConfigured ?? this.inputConfigured,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          defaultPlaybackSpeed == other.defaultPlaybackSpeed &&
          toleranceLevel == other.toleranceLevel &&
          minVolumeThreshold == other.minVolumeThreshold &&
          referenceFrequency == other.referenceFrequency &&
          customApiBaseUrl == other.customApiBaseUrl &&
          inputSource == other.inputSource &&
          inputConfigured == other.inputConfigured;

  @override
  int get hashCode => Object.hash(
    themeMode,
    defaultPlaybackSpeed,
    toleranceLevel,
    minVolumeThreshold,
    referenceFrequency,
    customApiBaseUrl,
    inputSource,
    inputConfigured,
  );
}

/// Stores and retrieves user preferences using SharedPreferences.
class SettingsRepository {
  static const _prefix = 'settings.';
  static const _themeModeKey = '${_prefix}themeMode';
  static const _speedKey = '${_prefix}defaultSpeed';
  static const _toleranceKey = '${_prefix}tolerance';
  static const _volumeKey = '${_prefix}minVolume';
  static const _referenceFreqKey = '${_prefix}referenceFreq';
  static const _customApiUrlKey = '${_prefix}customApiUrl';
  static const _inputSourceKey = '${_prefix}inputSource';
  static const _inputConfiguredKey = '${_prefix}inputConfigured';

  Future<AppSettings> read() async {
    final prefs = await SharedPreferences.getInstance();

    final themeStr = prefs.getString(_themeModeKey);
    final themeMode = switch (themeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final speed = prefs.getDouble(_speedKey) ?? 1.0;

    final tolStr = prefs.getString(_toleranceKey);
    final tolerance = switch (tolStr) {
      'relaxed' => ToleranceLevel.relaxed,
      'strict' => ToleranceLevel.strict,
      _ => ToleranceLevel.normal,
    };

    final volume = prefs.getDouble(_volumeKey) ?? 0.1;
    final refFreq = prefs.getDouble(_referenceFreqKey) ?? 440.0;
    final customUrl = prefs.getString(_customApiUrlKey);

    final inputSourceStr = prefs.getString(_inputSourceKey);
    final inputSource = switch (inputSourceStr) {
      'microphone' => PracticeInputSource.microphone,
      'midi' => PracticeInputSource.midi,
      _ => PracticeInputSource.both,
    };

    return AppSettings(
      themeMode: themeMode,
      defaultPlaybackSpeed: speed,
      toleranceLevel: tolerance,
      minVolumeThreshold: volume,
      referenceFrequency: refFreq,
      customApiBaseUrl: customUrl,
      inputSource: inputSource,
      inputConfigured:
          prefs.getBool(_inputConfiguredKey) ??
          prefs.containsKey(_inputSourceKey),
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, settings.themeMode.name);
    await prefs.setDouble(_speedKey, settings.defaultPlaybackSpeed);
    await prefs.setString(_toleranceKey, settings.toleranceLevel.name);
    await prefs.setDouble(_volumeKey, settings.minVolumeThreshold);
    await prefs.setDouble(_referenceFreqKey, settings.referenceFrequency);
    await prefs.setString(_inputSourceKey, settings.inputSource.name);
    await prefs.setBool(_inputConfiguredKey, settings.inputConfigured);

    if (settings.customApiBaseUrl != null &&
        settings.customApiBaseUrl!.trim().isNotEmpty) {
      await prefs.setString(
        _customApiUrlKey,
        settings.customApiBaseUrl!.trim(),
      );
    } else {
      await prefs.remove(_customApiUrlKey);
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final current = await read();
    await save(current.copyWith(themeMode: mode));
  }

  Future<void> updateSpeed(double speed) async {
    final current = await read();
    await save(current.copyWith(defaultPlaybackSpeed: speed));
  }

  Future<void> updateTolerance(ToleranceLevel level) async {
    final current = await read();
    await save(current.copyWith(toleranceLevel: level));
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class SettingsNotifier extends Notifier<AppSettings> {
  SettingsNotifier({AppSettings? initialSettings})
    : _initialSettings = initialSettings;

  final AppSettings? _initialSettings;

  @override
  AppSettings build() {
    if (_initialSettings != null) return _initialSettings;
    final repo = ref.watch(settingsRepositoryProvider);
    // Asynchronously hydrate persisted preferences
    repo.read().then((persisted) {
      state = persisted;
    });
    return const AppSettings();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final repo = ref.read(settingsRepositoryProvider);
    await repo.save(state);
  }

  Future<void> setDefaultSpeed(double speed) async {
    state = state.copyWith(defaultPlaybackSpeed: speed);
    final repo = ref.read(settingsRepositoryProvider);
    await repo.save(state);
  }

  Future<void> setToleranceLevel(ToleranceLevel level) async {
    state = state.copyWith(toleranceLevel: level);
    final repo = ref.read(settingsRepositoryProvider);
    await repo.save(state);
  }

  Future<void> setInputSource(PracticeInputSource source) async {
    state = state.copyWith(inputSource: source, inputConfigured: true);
    final repo = ref.read(settingsRepositoryProvider);
    await repo.save(state);
  }

  Future<void> setCustomApiBaseUrl(String? url) async {
    state = state.copyWith(
      customApiBaseUrl: url,
      clearCustomApiBaseUrl: url == null || url.trim().isEmpty,
    );
    final repo = ref.read(settingsRepositoryProvider);
    await repo.save(state);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider.select((s) => s.themeMode));
});
