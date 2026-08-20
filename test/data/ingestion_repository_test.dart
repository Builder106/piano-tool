import 'dart:convert' show jsonEncode, utf8;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:piano_tool/data/ingestion_repository.dart';
import 'package:piano_tool/models/level_models.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('IngestionRepository', () {
    late IngestionRepository repository;

    setUp(() {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/jobs' && request.method == 'POST') {
          return http.Response('{"job_id": "job-123", "status": "queued"}', 202);
        }
        if (request.url.path.startsWith('/jobs/') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'status': 'done',
              'level': {
                'id': 'level_test',
                'title': 'Test Level',
                'description': 'A test level',
                'tempo': 120,
                'beatsPerMeasure': 4,
                'totalMeasures': 1,
                'measures': [
                  {
                    'index': 0,
                    'startBeat': 0.0,
                    'beatsPerMeasure': 4,
                    'notes': [
                      {
                        'midiNote': 60,
                        'startBeat': 0.0,
                        'durationBeats': 1.0,
                        'measureIndex': 0,
                        'beatIndex': 0,
                        'isRest': false,
                        'voiceIndex': 0,
                      }
                    ]
                  }
                ],
                'clefOctave': 4,
                'transpose': 0,
              }
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      repository = IngestionRepository(
        client: mockClient,
        baseUrl: 'http://test.api',
        prefs: prefs,
      );
    });

    test('submitYoutubeUrl returns jobId on success', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/jobs' && request.method == 'POST') {
          final body = request.body;
          expect(body, contains('"source":"youtube"'));
          expect(body, contains('"youtube_url":"https://youtube.com/watch?v=abc"'));
          return http.Response('{"job_id": "job-456", "status": "queued"}', 202);
        }
        return http.Response('Not found', 404);
      });
      repository = IngestionRepository(
        client: mockClient,
        baseUrl: 'http://test.api',
        prefs: prefs,
      );

      final jobId = await repository.submitYoutubeUrl('https://youtube.com/watch?v=abc');
      expect(jobId, 'job-456');
    });

    test('pollJob returns IngestionJobResult with done status and level', () async {
      final status = await repository.pollJob('job-123');
      expect(status.status, IngestionJobStatus.done);
      expect(status.level, isNotNull);
      expect(status.level!.title, 'Test Level');
    });

    test('pollJob returns IngestionJobResult with failed status and error', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/jobs/job-123' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'status': 'failed',
              'error': 'No notes detected',
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });
      repository = IngestionRepository(
        client: mockClient,
        baseUrl: 'http://test.api',
        prefs: prefs,
      );

      final status = await repository.pollJob('job-123');
      expect(status.status, IngestionJobStatus.failed);
      expect(status.error, 'No notes detected');
    });

    test('saveLevel persists level and appears in listImportedLevels', () async {
      const level = LevelModel(
        id: 'imported_1',
        title: 'Imported Song',
        description: 'From audio',
        tempo: 100,
        beatsPerMeasure: 4,
        totalMeasures: 2,
        measures: [],
      );

      await repository.saveLevel(level);

      final levels = await repository.listImportedLevels();
      expect(levels.length, 1);
      expect(levels.first.id, 'imported_1');
      expect(levels.first.title, 'Imported Song');
    });

    test('listImportedLevels returns empty list when no levels saved', () async {
      final levels = await repository.listImportedLevels();
      expect(levels, isEmpty);
    });

    test('deleteImportedLevel removes level from list', () async {
      const level = LevelModel(
        id: 'imported_1',
        title: 'Imported Song',
        description: 'From audio',
        tempo: 100,
        beatsPerMeasure: 4,
        totalMeasures: 2,
        measures: [],
      );

      await repository.saveLevel(level);
      await repository.deleteImportedLevel('imported_1');

      final levels = await repository.listImportedLevels();
      expect(levels, isEmpty);
    });

    test('submitUpload returns jobId on success', () async {
      final tempFile = File(
        '${Directory.systemTemp.path}/ingestion_repository_test_${DateTime.now().microsecondsSinceEpoch}.wav',
      );
      await tempFile.writeAsBytes([1, 2, 3, 4, 5]);
      addTearDown(() async {
        if (await tempFile.exists()) await tempFile.delete();
      });

      final mockClient = MockClient((request) async {
        if (request.url.path == '/jobs' && request.method == 'POST') {
          expect(request.headers['content-type'], contains('multipart/form-data'));
          return http.Response('{"job_id": "job-upload-1", "status": "queued"}', 202);
        }
        return http.Response('Not found', 404);
      });
      repository = IngestionRepository(
        client: mockClient,
        baseUrl: 'http://test.api',
        prefs: prefs,
      );

      final jobId = await repository.submitUpload(tempFile);
      expect(jobId, 'job-upload-1');
    });

    test('pollJob wraps a SocketException as an IngestionException', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Failed host lookup');
      });
      repository = IngestionRepository(
        client: mockClient,
        baseUrl: 'http://test.api',
        prefs: prefs,
      );

      expect(
        () => repository.pollJob('job-123'),
        throwsA(isA<IngestionException>()),
      );
    });

    test('pollJob wraps malformed JSON as an IngestionException', () async {
      final mockClient = MockClient((request) async {
        return http.Response('not json', 200);
      });
      repository = IngestionRepository(
        client: mockClient,
        baseUrl: 'http://test.api',
        prefs: prefs,
      );

      expect(
        () => repository.pollJob('job-123'),
        throwsA(isA<IngestionException>()),
      );
    });

    test('submitYoutubeUrl wraps a ClientException as an IngestionException', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });
      repository = IngestionRepository(
        client: mockClient,
        baseUrl: 'http://test.api',
        prefs: prefs,
      );

      expect(
        () => repository.submitYoutubeUrl('https://youtube.com/watch?v=abc'),
        throwsA(isA<IngestionException>()),
      );
    });

    test('submitUpload uses a content type derived from the file extension', () async {
      final tempFile = File(
        '${Directory.systemTemp.path}/ingestion_repository_test_mp3_${DateTime.now().microsecondsSinceEpoch}.mp3',
      );
      await tempFile.writeAsBytes([1, 2, 3, 4, 5]);
      addTearDown(() async {
        if (await tempFile.exists()) await tempFile.delete();
      });

      final mockClient = MockClient((request) async {
        // MockClient finalizes the request before calling the callback, so the
        // request body is already available as request.bodyBytes.
        final body = utf8.decode(request.bodyBytes);
        // Multipart body uses lowercase 'content-type:' header
        expect(body, contains('content-type: audio/mpeg'));
        return http.Response('{"job_id": "job-mp3-1", "status": "queued"}', 202);
      });
      repository = IngestionRepository(
        client: mockClient,
        baseUrl: 'http://test.api',
        prefs: prefs,
      );

      final jobId = await repository.submitUpload(tempFile);
      expect(jobId, 'job-mp3-1');
    });

    test('submitUpload falls back to octet-stream for an unknown extension', () async {
      final tempFile = File(
        '${Directory.systemTemp.path}/ingestion_repository_test_xyz_${DateTime.now().microsecondsSinceEpoch}.xyz',
      );
      await tempFile.writeAsBytes([1, 2, 3, 4, 5]);
      addTearDown(() async {
        if (await tempFile.exists()) await tempFile.delete();
      });

      final mockClient = MockClient((request) async {
        final body = utf8.decode(request.bodyBytes);
        expect(body, contains('content-type: application/octet-stream'));
        return http.Response('{"job_id": "job-xyz-1", "status": "queued"}', 202);
      });
      repository = IngestionRepository(
        client: mockClient,
        baseUrl: 'http://test.api',
        prefs: prefs,
      );

      await repository.submitUpload(tempFile);
    });

    test('cancelJob succeeds on a 200 response', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/jobs/job-123');
        return http.Response('', 200);
      });
      repository = IngestionRepository(
        client: mockClient,
        baseUrl: 'http://test.api',
        prefs: prefs,
      );

      await repository.cancelJob('job-123');
    });

    test('cancelJob throws IngestionException on a failure response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not found', 404);
      });
      repository = IngestionRepository(
        client: mockClient,
        baseUrl: 'http://test.api',
        prefs: prefs,
      );

      expect(
        () => repository.cancelJob('job-123'),
        throwsA(isA<IngestionException>()),
      );
    });

    test('submitRecording returns jobId on success', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/jobs' && request.method == 'POST') {
          // For multipart requests, body is not JSON - just verify it's a multipart request
          expect(request.headers['content-type'], contains('multipart/form-data'));
          return http.Response('{"job_id": "job-789", "status": "queued"}', 202);
        }
        return http.Response('Not found', 404);
      });
      repository = IngestionRepository(
        client: mockClient,
        baseUrl: 'http://test.api',
        prefs: prefs,
      );

      final jobId = await repository.submitRecording(Uint8List.fromList([1, 2, 3, 4, 5]));
      expect(jobId, 'job-789');
    });
  });
}