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

  factory IngestionJobResult.fromJson(Map<String, dynamic> json) {
    return IngestionJobResult(
      status: _parseStatus(json['status'] as String? ?? 'queued'),
      error: json['error'] as String?,
      level: json['level'] != null
          ? LevelModel.fromJson(json['level'] as Map<String, dynamic>)
          : null,
    );
  }

  static IngestionJobStatus _parseStatus(String status) {
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
  static const _levelsKey = 'ingestion.levels';

  final http.Client _client;
  final String _baseUrl;
  final SharedPreferences _prefs;

  IngestionRepository({
    required http.Client client,
    required String baseUrl,
    required SharedPreferences prefs,
  })  : _client = client,
        _baseUrl = baseUrl,
        _prefs = prefs;

  /// Submit an audio file for transcription
  Future<String> submitUpload(File file) => _guard(() async {
        final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/jobs'));
        request.fields['source'] = 'upload';
        request.fields['title'] = file.path.split('/').last;
        request.files.add(await http.MultipartFile.fromPath(
          'audio',
          file.path,
          contentType: _mediaTypeForPath(file.path),
        ));

        final response = await _client.send(request);
        if (response.statusCode != 202) {
          throw IngestionException('Failed to submit upload: ${response.statusCode}');
        }

        final responseBody = await response.stream.bytesToString();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        return json['job_id'] as String;
      });

  /// Submit a YouTube URL for transcription
  Future<String> submitYoutubeUrl(String url) => _guard(() async {
        final response = await _client.post(
          Uri.parse('$_baseUrl/jobs'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'source': 'youtube',
            'youtube_url': url,
            'title': 'YouTube Import',
          }),
        );

        if (response.statusCode != 202) {
          throw IngestionException('Failed to submit YouTube URL: ${response.statusCode}');
        }

        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['job_id'] as String;
      });

  /// Submit a recording (audio bytes) for transcription
  Future<String> submitRecording(Uint8List audioBytes) => _guard(() async {
        final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/jobs'));
        request.fields['source'] = 'upload';
        request.fields['title'] = 'Recording ${DateTime.now().millisecondsSinceEpoch}';
        request.files.add(http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: 'recording.wav',
          contentType: MediaType('audio', 'wav'),
        ));

        final response = await _client.send(request);
        if (response.statusCode != 202) {
          throw IngestionException('Failed to submit recording: ${response.statusCode}');
        }

        final responseBody = await response.stream.bytesToString();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        return json['job_id'] as String;
      });

  /// Poll a job for its status
  Future<IngestionJobResult> pollJob(String jobId) => _guard(() async {
        final response = await _client.get(Uri.parse('$_baseUrl/jobs/$jobId'));

        if (response.statusCode == 404) {
          throw IngestionException('Job not found: $jobId');
        }

        if (response.statusCode != 200) {
          throw IngestionException('Failed to poll job: ${response.statusCode}');
        }

        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return IngestionJobResult.fromJson(json);
      });

  /// Cancel a running job
  Future<void> cancelJob(String jobId) => _guard(() async {
        final response = await _client.delete(Uri.parse('$_baseUrl/jobs/$jobId'));
        if (response.statusCode != 200 && response.statusCode != 204) {
          throw IngestionException('Failed to cancel job: ${response.statusCode}');
        }
      });

  /// Save an imported level to local storage
  Future<void> saveLevel(LevelModel level) => _guard(() async {
        final levels = await _loadLevels();
        levels[level.id] = level;
        await _saveLevels(levels);
      });

  /// List all imported levels
  Future<List<LevelModel>> listImportedLevels() => _guard(() async {
        final levels = await _loadLevels();
        final list = levels.values.toList();
        // Sort by most recent first (we don't have timestamps, so use ID as proxy)
        list.sort((a, b) => b.id.compareTo(a.id));
        return list;
      });

  /// Delete an imported level
  Future<void> deleteImportedLevel(String levelId) => _guard(() async {
        final levels = await _loadLevels();
        levels.remove(levelId);
        await _saveLevels(levels);
      });

  /// Runs [body], converting any exception that escapes it into an
  /// [IngestionException] -- callers (the ImportScreen/ReviewScreen UI) only
  /// ever want to handle one exception type, but the underlying HTTP client,
  /// JSON decoding, and shared_preferences calls can throw
  /// [http.ClientException]/[SocketException]/[FormatException]/cast errors
  /// on their own.
  Future<T> _guard<T>(Future<T> Function() body) async {
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
  static MediaType _mediaTypeForPath(String path) {
    final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
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
    final raw = _prefs.getString(_levelsKey);
    if (raw == null) return {};

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return json.map((key, value) => MapEntry(
            key,
            LevelModel.fromJson(value as Map<String, dynamic>),
          ));
    } catch (_) {
      // Corrupt data - return empty map
      return {};
    }
  }

  Future<void> _saveLevels(Map<String, LevelModel> levels) async {
    final json = levels.map((key, value) => MapEntry(key, value.toJson()));
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
final ingestionRepositoryProvider = FutureProvider<IngestionRepository>((ref) async {
  // Base URL can be configured via --dart-define=INGESTION_API_BASE_URL
  const baseUrl = String.fromEnvironment(
    'INGESTION_API_BASE_URL',
    defaultValue: 'http://ampere-dev.local:8000',
  );

  final prefs = await SharedPreferences.getInstance();
  return IngestionRepository(
    client: http.Client(),
    baseUrl: baseUrl,
    prefs: prefs,
  );
});