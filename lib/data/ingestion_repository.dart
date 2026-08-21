import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/level_models.dart';

/// Status of an ingestion job
enum IngestionJobStatus {
  queued,
  downloading,
  transcribing,
  done,
  failed,
}

/// Result of polling a job
class IngestionJobResult {
  final IngestionJobStatus status;
  final String? error;
  final LevelModel? level;

  IngestionJobResult({
    required this.status,
    this.error,
    this.level,
  });

  factory IngestionJobResult.fromJson(final Map<String, dynamic> json) {
    return IngestionJobResult(
      status: _parseStatus(json['status'] as String? ?? 'queued'),
      error: json['error'] as String?,
      level: json['level'] != null
          ? LevelModel.fromJson(json['level'] as Map<String, dynamic>)
          : null,
    );
  }

  static IngestionJobStatus _parseStatus(final String status) {
    switch (status) {
      case 'queued':
        return IngestionJobStatus.queued;
      case 'downloading':
        return IngestionJobStatus.downloading;
      case 'transcribing':
        return IngestionJobStatus.transcribing;
      case 'done':
        return IngestionJobStatus.done;
      case 'failed':
        return IngestionJobStatus.failed;
      default:
        return IngestionJobStatus.queued;
    }
  }
}

/// Repository for audio ingestion operations
class IngestionRepository {
  static const String _levelsKey = 'ingestion.levels';

  final http.Client _client;
  final String _baseUrl;
  final SharedPreferences _prefs;

  IngestionRepository({
    required final http.Client client,
    required final String baseUrl,
    required final SharedPreferences prefs,
  })  : _client = client,
        _baseUrl = baseUrl,
        _prefs = prefs;

  /// Submit an audio file for transcription
  Future<String> submitUpload(final File file) => _guard<String>(() async {
        final http.MultipartRequest request =
            http.MultipartRequest('POST', Uri.parse('$_baseUrl/jobs'));
        request.fields['source'] = 'upload';
        request.fields['title'] = file.path.split('/').last;
        request.files.add(await http.MultipartFile.fromPath(
          'audio',
          file.path,
          contentType: _mediaTypeForPath(file.path),
        ));

        final http.StreamedResponse response = await _client.send(request);
        if (response.statusCode != 202) {
          throw IngestionException(
              'Failed to submit upload: ${response.statusCode}');
        }

        final String responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> json =
            jsonDecode(responseBody) as Map<String, dynamic>;
        return json['job_id'] as String;
      });

  /// Submit a YouTube URL for transcription
  Future<String> submitYoutubeUrl(final String url) => _guard<String>(() async {
        final http.Response response = await _client.post(
          Uri.parse('$_baseUrl/jobs'),
          headers: <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'source': 'youtube',
            'youtube_url': url,
            'title': 'YouTube Import',
          }),
        );

        if (response.statusCode != 202) {
          throw IngestionException(
              'Failed to submit YouTube URL: ${response.statusCode}');
        }

        final Map<String, dynamic> json =
            jsonDecode(response.body) as Map<String, dynamic>;
        return json['job_id'] as String;
      });

  /// Submit a recording (audio bytes) for transcription
  Future<String> submitRecording(final Uint8List audioBytes) =>
      _guard<String>(() async {
        final http.MultipartRequest request =
            http.MultipartRequest('POST', Uri.parse('$_baseUrl/jobs'));
        request.fields['source'] = 'upload';
        request.fields['title'] =
            'Recording ${DateTime.now().millisecondsSinceEpoch}';
        request.files.add(http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: 'recording.wav',
          contentType: MediaType('audio', 'wav'),
        ));

        final http.StreamedResponse response = await _client.send(request);
        if (response.statusCode != 202) {
          throw IngestionException(
              'Failed to submit recording: ${response.statusCode}');
        }

        final String responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> json =
            jsonDecode(responseBody) as Map<String, dynamic>;
        return json['job_id'] as String;
      });

  /// Poll a job for its status
  Future<IngestionJobResult> pollJob(final String jobId) =>
      _guard<IngestionJobResult>(() async {
        final http.Response response =
            await _client.get(Uri.parse('$_baseUrl/jobs/$jobId'));

        if (response.statusCode == 404) {
          throw IngestionException('Job not found: $jobId');
        }

        if (response.statusCode != 200) {
          throw IngestionException(
              'Failed to poll job: ${response.statusCode}');
        }

        final Map<String, dynamic> json =
            jsonDecode(response.body) as Map<String, dynamic>;
        return IngestionJobResult.fromJson(json);
      });

  /// Cancel a running job
  Future<void> cancelJob(final String jobId) => _guard<void>(() async {
        final http.Response response =
            await _client.delete(Uri.parse('$_baseUrl/jobs/$jobId'));
        if (response.statusCode != 200 && response.statusCode != 204) {
          throw IngestionException(
              'Failed to cancel job: ${response.statusCode}');
        }
      });

  /// Save an imported level to local storage
  Future<void> saveLevel(final LevelModel level) => _guard<void>(() async {
        final Map<String, LevelModel> levels = await _loadLevels();
        levels[level.id] = level;
        await _saveLevels(levels);
      });

  /// List all imported levels
  Future<List<LevelModel>> listImportedLevels() =>
      _guard<List<LevelModel>>(() async {
        final Map<String, LevelModel> levels = await _loadLevels();
        final List<LevelModel> list = levels.values.toList();
        // Sort by most recent first (we don't have timestamps, so use ID as proxy)
        list.sort(
            (final LevelModel a, final LevelModel b) => b.id.compareTo(a.id));
        return list;
      });

  /// Delete an imported level
  Future<void> deleteImportedLevel(final String levelId) =>
      _guard<void>(() async {
        final Map<String, LevelModel> levels = await _loadLevels();
        levels.remove(levelId);
        await _saveLevels(levels);
      });

  /// Runs [body], converting any exception that escapes it into an
  /// [IngestionException] -- callers (the ImportScreen/ReviewScreen UI) only
  /// ever want to handle one exception type, but the underlying HTTP client,
  /// JSON decoding, and shared_preferences calls can throw
  /// [http.ClientException]/[SocketException]/[FormatException]/cast errors
  /// on their own.
  Future<T> _guard<T>(final Future<T> Function() body) async {
    try {
      return await body();
    } on IngestionException {
      rethrow;
    } catch (e) {
      throw IngestionException('$e');
    }
  }

  /// Maps a file's extension to the MIME type sent to the ingestion backend.
  /// [ImportScreen] lets the user pick any [FileType.audio] file, which can
  /// resolve to formats other than wav.
  static MediaType _mediaTypeForPath(final String path) {
    final String ext =
        path.contains('.') ? path.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'wav':
        return MediaType('audio', 'wav');
      case 'mp3':
        return MediaType('audio', 'mpeg');
      case 'm4a':
        return MediaType('audio', 'mp4');
      case 'flac':
        return MediaType('audio', 'flac');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  Future<Map<String, LevelModel>> _loadLevels() async {
    final String? raw = _prefs.getString(_levelsKey);
    if (raw == null) {
      return <String, LevelModel>{};
    }

    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      return json.map(
        (final String key, final dynamic value) => MapEntry<String, LevelModel>(
          key,
          LevelModel.fromJson(value as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      // Corrupt data - return empty map
      return <String, LevelModel>{};
    }
  }

  Future<void> _saveLevels(final Map<String, LevelModel> levels) async {
    final Map<String, dynamic> json = levels.map(
      (final String key, final LevelModel value) =>
          MapEntry<String, dynamic>(key, value.toJson()),
    );
    await _prefs.setString(_levelsKey, jsonEncode(json));
  }
}

/// Exception for ingestion errors
class IngestionException implements Exception {
  final String message;

  IngestionException(this.message);

  @override
  String toString() => 'IngestionException: $message';
}

/// Riverpod provider for IngestionRepository
final FutureProvider<IngestionRepository> ingestionRepositoryProvider =
    FutureProvider<IngestionRepository>(
        (final Ref ref) async {
  // Base URL can be configured via --dart-define=INGESTION_API_BASE_URL
  const String baseUrl = String.fromEnvironment(
    'INGESTION_API_BASE_URL',
    defaultValue: 'http://ampere-dev.local:8000',
  );

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return IngestionRepository(
    client: http.Client(),
    baseUrl: baseUrl,
    prefs: prefs,
  );
});
