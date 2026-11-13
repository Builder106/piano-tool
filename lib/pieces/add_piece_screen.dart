import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../brand/book_page.dart';
import '../brand/buttons.dart';
import '../brand/choices.dart';
import '../brand/palette.dart';
import '../data/ingestion_repository.dart';
import '../data/level_repository.dart';
import '../models/engine_models.dart';
import '../models/level_models.dart';
import '../practice/paper_staff.dart';
import 'import_inputs.dart';

/// Opens Add a piece. Pops with the new piece's stage id when one was kept.
Route<String> addPieceRoute() => fadeRoute((_) => const AddPieceScreen());

enum PieceSource { recording, file, youtube }

/// Whether [url] looks like a youtube.com or youtu.be link. The service gets
/// whatever is typed otherwise.
bool isYoutubeLink(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
  final host = uri.host.toLowerCase();
  return host == 'youtube.com' ||
      host.endsWith('.youtube.com') ||
      host == 'youtu.be';
}

enum _Step { choose, working, review, failed }

/// Make a piece from a recording, an audio file or a YouTube link: the service
/// writes down the notes, the learner looks at them, names the piece and keeps
/// it.
class AddPieceScreen extends ConsumerStatefulWidget {
  const AddPieceScreen({
    super.key,
    this.pollEvery = const Duration(seconds: 2),
    this.giveUpAfter = const Duration(minutes: 5),
  });

  final Duration pollEvery;
  final Duration giveUpAfter;

  @override
  ConsumerState<AddPieceScreen> createState() => _AddPieceScreenState();
}

class _AddPieceScreenState extends ConsumerState<AddPieceScreen> {
  _Step _step = _Step.choose;
  PieceSource _source = PieceSource.recording;
  final _link = TextEditingController();
  final _title = TextEditingController();
  File? _file;
  Uint8List? _recording;
  bool _recordingNow = false;
  String? _note;
  IngestionJobStatus _status = IngestionJobStatus.queued;
  String? _jobId;
  LevelModel? _level;
  String _failure = '';

  @override
  void initState() {
    super.initState();
    _link.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _jobId = null;
    _link.dispose();
    _title.dispose();
    super.dispose();
  }

  bool get _ready => switch (_source) {
    PieceSource.recording => _recording != null && !_recordingNow,
    PieceSource.file => _file != null,
    PieceSource.youtube => isYoutubeLink(_link.text),
  };

  Future<void> _pickFile() async {
    final file = await ref.read(importInputsProvider).pickAudioFile();
    if (mounted && file != null) setState(() => _file = file);
  }

  Future<void> _toggleRecording() async {
    final inputs = ref.read(importInputsProvider);
    if (_recordingNow) {
      final bytes = await inputs.stopRecording();
      if (!mounted) return;
      setState(() {
        _recordingNow = false;
        _recording = bytes;
        _note = null;
      });
    } else {
      final started = await inputs.startRecording();
      if (!mounted) return;
      setState(() {
        _recordingNow = started;
        _recording = null;
        _note = started
            ? null
            : 'The microphone is not allowed. Allow it in your settings, or '
                  'choose a file instead.';
      });
    }
  }

  Future<void> _make() async {
    setState(() {
      _step = _Step.working;
      _status = IngestionJobStatus.queued;
    });
    try {
      final repo = await ref.read(ingestionRepositoryProvider.future);
      final jobId = switch (_source) {
        PieceSource.recording => await repo.submitRecording(_recording!),
        PieceSource.file => await repo.submitUpload(_file!),
        PieceSource.youtube => await repo.submitYoutubeUrl(_link.text.trim()),
      };
      if (!mounted) return;
      _jobId = jobId;
      await _wait(repo, jobId);
    } on Object {
      _fail('The piece could not be made. Check the connection and try again.');
    }
  }

  Future<void> _wait(IngestionRepository repo, String jobId) async {
    final polls =
        widget.giveUpAfter.inMilliseconds ~/
        widget.pollEvery.inMilliseconds.clamp(1, 1 << 30);
    for (var i = 0; i < polls; i++) {
      await Future<void>.delayed(widget.pollEvery);
      if (!mounted || _jobId != jobId) return;
      final result = await repo.pollJob(jobId);
      if (!mounted || _jobId != jobId) return;
      switch (result.status) {
        case IngestionJobStatus.done:
          final level = result.level;
          if (level == null) {
            _fail('No notes came back. Try again, a little slower.');
          } else {
            _title.text = level.title;
            setState(() {
              _level = level;
              _step = _Step.review;
            });
          }
          return;
        case IngestionJobStatus.failed || IngestionJobStatus.cancelled:
          _fail(result.error ?? 'That did not work. Try again.');
          return;
        case _:
          setState(() => _status = result.status);
      }
    }
    _fail('That took too long. Try a shorter piece.');
  }

  void _fail(String message) {
    if (!mounted) return;
    _jobId = null;
    setState(() {
      _failure = message;
      _step = _Step.failed;
    });
  }

  Future<void> _stop() async {
    final jobId = _jobId;
    _jobId = null;
    setState(() => _step = _Step.choose);
    if (jobId == null) return;
    try {
      final repo = await ref.read(ingestionRepositoryProvider.future);
      await repo.cancelJob(jobId);
    } on Object {
      // The service finishes it on its own.
    }
  }

  Future<void> _keep() async {
    final level = _level;
    if (level == null) return;
    final name = _title.text.trim();
    final kept = name.isEmpty ? level : level.copyWith(title: name);
    final repo = await ref.read(ingestionRepositoryProvider.future);
    await repo.saveLevel(kept);
    ref.invalidate(levelRepositoryProvider);
    if (mounted) Navigator.of(context).pop('imported_${kept.id}');
  }

  void _again() => setState(() {
    _step = _Step.choose;
    _level = null;
    _jobId = null;
  });

  @override
  Widget build(BuildContext context) {
    ref.watch(importInputsProvider);
    final u = unitOf(context);
    final content = switch (_step) {
      _Step.choose => _choose(u),
      _Step.working => _working(u),
      _Step.review => _review(u),
      _Step.failed => _failed(u),
    };
    return BookPage(
      title: 'Add a piece',
      child: ListView(
        padding: EdgeInsets.fromLTRB(40 * u, 32 * u, 40 * u, 48 * u),
        children: content,
      ),
    );
  }

  List<Widget> _choose(double u) => [
    const PageHeading('How will you show it?'),
    SizedBox(height: 8 * u),
    Choices<PieceSource>(
      options: const [
        (PieceSource.recording, 'Play it now'),
        (PieceSource.file, 'Audio file'),
        (PieceSource.youtube, 'YouTube link'),
      ],
      value: _source,
      onChanged: (s) => setState(() {
        _source = s;
        _note = null;
      }),
    ),
    SizedBox(height: 20 * u),
    ...switch (_source) {
      PieceSource.recording => [
        PageText(
          _recordingNow
              ? 'Recording. Play the piece, then press Stop.'
              : _recording != null
              ? 'Recorded. Make the piece, or record it again.'
              : 'Play the piece once through, slowly and clearly. One hand '
                    'at a time works best.',
        ),
        SizedBox(height: 16 * u),
        Align(
          alignment: Alignment.centerLeft,
          child: _recordingNow
              ? StartButton(label: 'Stop', onPressed: _toggleRecording)
              : QuietButton(
                  label: _recording == null
                      ? 'Start recording'
                      : 'Record again',
                  onPressed: _toggleRecording,
                ),
        ),
      ],
      PieceSource.file => [
        PageText(
          _file == null
              ? 'Pick a recording of one instrument playing the piece.'
              : 'Chosen: ${_file!.uri.pathSegments.last}',
        ),
        SizedBox(height: 16 * u),
        Align(
          alignment: Alignment.centerLeft,
          child: QuietButton(
            label: _file == null ? 'Choose a file' : 'Choose another',
            onPressed: _pickFile,
          ),
        ),
      ],
      PieceSource.youtube => [
        const PageText('Paste the link to a video of the piece being played.'),
        SizedBox(height: 12 * u),
        TextField(
          controller: _link,
          keyboardType: TextInputType.url,
          autocorrect: false,
          cursorColor: Palette.pencilBlue,
          style: TextStyle(
            fontFamily: Fonts.ui,
            fontSize: 24 * u,
            color: Palette.ink,
          ),
          decoration: const InputDecoration(
            hintText: 'youtube.com/watch?v=…',
            hintStyle: TextStyle(color: Palette.graphite),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Palette.ink, width: 2),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Palette.pencilBlue, width: 3),
            ),
          ),
        ),
        if (_link.text.trim().isNotEmpty && !isYoutubeLink(_link.text))
          Padding(
            padding: EdgeInsets.only(top: 8 * u),
            child: const PageText(
              'That does not look like a youtube.com or youtu.be link.',
              color: Palette.ink,
            ),
          ),
      ],
    },
    if (_note != null) ...[
      SizedBox(height: 12 * u),
      PageText(_note!, color: Palette.ink),
    ],
    SizedBox(height: 32 * u),
    Align(
      alignment: Alignment.centerLeft,
      child: StartButton(
        label: 'Make the piece',
        onPressed: _ready ? _make : null,
      ),
    ),
  ];

  List<Widget> _working(double u) => [
    const PageHeading('Making your piece'),
    SizedBox(height: 8 * u),
    PageText(switch (_status) {
      IngestionJobStatus.downloading => 'Fetching the sound.',
      IngestionJobStatus.transcribing => 'Listening for the notes.',
      _ => 'Waiting for its turn.',
    }),
    SizedBox(height: 4 * u),
    const PageText('This can take a minute or two.'),
    SizedBox(height: 28 * u),
    Align(
      alignment: Alignment.centerLeft,
      child: QuietButton(label: 'Stop', onPressed: _stop),
    ),
  ];

  List<Widget> _review(double u) {
    final level = _level!;
    final notes = notesOf(level);
    return [
      const PageHeading('Is this your piece?'),
      SizedBox(height: 16 * u),
      TextField(
        controller: _title,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: Palette.pencilBlue,
        style: TextStyle(
          fontFamily: Fonts.ui,
          fontSize: 32 * u,
          color: Palette.ink,
          fontVariations: const [FontVariation('wght', 800)],
        ),
        decoration: const InputDecoration(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Palette.ink, width: 2),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Palette.pencilBlue, width: 3),
          ),
        ),
      ),
      SizedBox(height: 20 * u),
      SizedBox(
        height: 210 * u,
        child: StaticStaff(
          level: level,
          notes: notes,
          noteStates: [for (final _ in notes) NoteState.upcoming],
        ),
      ),
      SizedBox(height: 12 * u),
      PageText(
        '${notes.length} notes in ${level.totalMeasures} '
        '${level.totalMeasures == 1 ? 'bar' : 'bars'}. If it looks wrong, '
        'throw it away and play it again, slower.',
      ),
      SizedBox(height: 28 * u),
      Wrap(
        spacing: 14 * u,
        runSpacing: 12 * u,
        children: [
          StartButton(label: 'Keep it', onPressed: _keep),
          QuietButton(label: 'Throw it away', onPressed: _again),
        ],
      ),
    ];
  }

  List<Widget> _failed(double u) => [
    const PageHeading('That did not work'),
    SizedBox(height: 8 * u),
    PageText(_failure),
    SizedBox(height: 28 * u),
    Align(
      alignment: Alignment.centerLeft,
      child: StartButton(label: 'Try again', onPressed: _again),
    ),
  ];
}
