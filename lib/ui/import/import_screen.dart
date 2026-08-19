import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';

import '../../data/ingestion_repository.dart';
import '../practice/mic_permission_gate.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  ImportSource _selectedSource = ImportSource.file;
  final _youtubeController = TextEditingController();
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isSubmitting = false;
  String? _jobId;
  IngestionJobStatus? _jobStatus;
  String? _youtubeError;
  Timer? _pollTimer;
  int _pollAttempts = 0;

  static const _pollInterval = Duration(seconds: 2);
  static const _pollTimeout = Duration(minutes: 5);
  // Counting ticks rather than comparing against a wall-clock deadline: the
  // test suite drives this timer forward with fake time via tester.pump(),
  // which advances Timer callbacks without advancing DateTime.now().
  static final _maxPollAttempts =
      _pollTimeout.inMilliseconds ~/ _pollInterval.inMilliseconds;

  @override
  void initState() {
    super.initState();
    // The submit button's enabled state depends on the typed URL, so a
    // controller edit has to trigger a rebuild of this widget too - a plain
    // TextField repaints itself on input but doesn't propagate upward.
    _youtubeController.addListener(_onYoutubeUrlChanged);
  }

  void _onYoutubeUrlChanged() => setState(() {});

  @override
  void dispose() {
    _youtubeController.removeListener(_onYoutubeUrlChanged);
    _youtubeController.dispose();
    _audioRecorder.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(ingestionRepositoryProvider);

    return repoAsync.when(
      data: (_) => _BuildImportScreen(
        selectedSource: _selectedSource,
        onSourceChanged: (source) => setState(() => _selectedSource = source),
        youtubeController: _youtubeController,
        isRecording: _isRecording,
        pickedFilePath: _pickedFilePath,
        recordedBytes: _recordedBytes,
        onPickFile: _pickFile,
        onStartRecording: _startRecording,
        onStopRecording: _stopRecording,
        onSubmit: _submit,
        isSubmitting: _isSubmitting,
        jobId: _jobId,
        jobStatus: _jobStatus,
        youtubeError: _youtubeError,
        onCancelJob: _cancelJob,
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error loading ingestion service: $error')),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null && mounted) {
      setState(() {
        _pickedFilePath = result.files.single.path!;
      });
    }
  }

  String? _pickedFilePath;

  Future<void> _submit() async {
    switch (_selectedSource) {
      case ImportSource.file:
        if (_pickedFilePath == null) {
          _showError('Please pick an audio file first');
          return;
        }
        break;
      case ImportSource.youtube:
        final url = _youtubeController.text.trim();
        if (url.isEmpty) {
          _showError('Please enter a YouTube URL');
          return;
        }
        final validationError = _validateYoutubeUrl(url);
        if (validationError != null) {
          setState(() => _youtubeError = validationError);
          return;
        }
        setState(() => _youtubeError = null);
        break;
      case ImportSource.recording:
        if (_recordedBytes == null) {
          _showError('Please record some audio first');
          return;
        }
        break;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = await ref.read(ingestionRepositoryProvider.future);

      final String jobId = switch (_selectedSource) {
        ImportSource.file => await repo.submitUpload(File(_pickedFilePath!)),
        ImportSource.youtube =>
          await repo.submitYoutubeUrl(_youtubeController.text.trim()),
        ImportSource.recording => await repo.submitRecording(_recordedBytes!),
      };

      if (!mounted) return;
      setState(() {
        _jobId = jobId;
        _jobStatus = IngestionJobStatus.queued;
      });
      _startPolling(jobId);
    } on IngestionException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError(e.message);
    }
  }

  /// Accepts only URLs that look like a youtube.com or youtu.be link -- the
  /// backend otherwise gets whatever string the user typed, verbatim.
  String? _validateYoutubeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Enter a valid URL';
    }
    final host = uri.host.toLowerCase();
    final isYoutube = host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'youtu.be' ||
        host.endsWith('.youtu.be');
    if (!isYoutube) {
      return 'Enter a youtube.com or youtu.be URL';
    }
    return null;
  }

  void _startPolling(String jobId) {
    _pollTimer?.cancel();
    _pollAttempts = 0;
    _pollTimer = Timer.periodic(_pollInterval, (timer) async {
      _pollAttempts++;
      if (_pollAttempts > _maxPollAttempts) {
        timer.cancel();
        if (!mounted) return;
        _showError('Transcription timed out. Please try again.');
        setState(() {
          _jobId = null;
          _jobStatus = null;
          _isSubmitting = false;
        });
        return;
      }

      try {
        final repo = await ref.read(ingestionRepositoryProvider.future);
        final result = await repo.pollJob(jobId);
        if (!mounted) return;

        if (result.status == IngestionJobStatus.done) {
          timer.cancel();
          setState(() {
            _isSubmitting = false;
            _jobStatus = result.status;
          });
          context.push('/review?jobId=$jobId');
        } else if (result.status == IngestionJobStatus.failed) {
          timer.cancel();
          _showError(result.error ?? 'Transcription failed');
          setState(() {
            _jobId = null;
            _jobStatus = null;
            _isSubmitting = false;
          });
        } else {
          // queued / downloading / transcribing: keep polling, but reflect
          // the current stage so the user isn't staring at a static spinner
          // for the whole job lifecycle.
          setState(() => _jobStatus = result.status);
        }
      } on IngestionException catch (e) {
        timer.cancel();
        if (!mounted) return;
        _showError(e.message);
        setState(() {
          _jobId = null;
          _jobStatus = null;
          _isSubmitting = false;
        });
      }
    });
  }

  Future<void> _cancelJob() async {
    _pollTimer?.cancel();
    final jobId = _jobId;
    setState(() {
      _jobId = null;
      _jobStatus = null;
      _isSubmitting = false;
    });
    if (jobId == null) return;
    try {
      final repo = await ref.read(ingestionRepositoryProvider.future);
      await repo.cancelJob(jobId);
    } on IngestionException catch (e) {
      if (!mounted) return;
      _showError('Failed to cancel: ${e.message}');
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final tempPath =
          '${Directory.systemTemp.path}/piano_tool_recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: tempPath,
      );
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    if (path != null) {
      final file = File(path);
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _recordedBytes = bytes;
        _isRecording = false;
      });
    }
  }

  Uint8List? _recordedBytes;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _BuildImportScreen extends StatelessWidget {
  const _BuildImportScreen({
    required this.selectedSource,
    required this.onSourceChanged,
    required this.youtubeController,
    required this.isRecording,
    required this.pickedFilePath,
    required this.recordedBytes,
    required this.onPickFile,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onSubmit,
    required this.isSubmitting,
    required this.jobId,
    required this.jobStatus,
    this.youtubeError,
    required this.onCancelJob,
  });

  final ImportSource selectedSource;
  final ValueChanged<ImportSource> onSourceChanged;
  final TextEditingController youtubeController;
  final bool isRecording;
  final String? pickedFilePath;
  final Uint8List? recordedBytes;
  final VoidCallback onPickFile;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final String? jobId;
  final IngestionJobStatus? jobStatus;
  final String? youtubeError;
  final VoidCallback onCancelJob;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(PianoSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Import Audio',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: PianoSpacing.lg),
                  _SourcePicker(
                    selectedSource: selectedSource,
                    onChanged: onSourceChanged,
                  ),
                  const SizedBox(height: PianoSpacing.lg),
                  _SourceInput(
                    source: selectedSource,
                    youtubeController: youtubeController,
                    isRecording: isRecording,
                    pickedFilePath: pickedFilePath,
                    recordedBytes: recordedBytes,
                    onPickFile: onPickFile,
                    onStartRecording: onStartRecording,
                    onStopRecording: onStopRecording,
                    youtubeError: youtubeError,
                  ),
                  const SizedBox(height: PianoSpacing.lg),
                  if (isSubmitting && jobId != null) ...[
                    _PollingStatus(
                      jobId: jobId!,
                      status: jobStatus,
                      onCancel: onCancelJob,
                    ),
                  ] else ...[
                    _SubmitButton(
                      source: selectedSource,
                      youtubeUrl: youtubeController.text,
                      isRecording: isRecording,
                      isSubmitting: isSubmitting,
                      onPressed: onSubmit,
                      pickedFilePath: pickedFilePath,
                      recordedBytes: recordedBytes,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ImportSource {
  file,
  youtube,
  recording,
}

class _SourcePicker extends StatelessWidget {
  const _SourcePicker({
    required this.selectedSource,
    required this.onChanged,
  });

  final ImportSource selectedSource;
  final ValueChanged<ImportSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SourceChip(
          label: 'File',
          icon: Icons.upload_file,
          selected: selectedSource == ImportSource.file,
          onTap: () => onChanged(ImportSource.file),
        ),
        const SizedBox(width: PianoSpacing.md),
        _SourceChip(
          label: 'YouTube',
          icon: Icons.play_circle_outline,
          selected: selectedSource == ImportSource.youtube,
          onTap: () => onChanged(ImportSource.youtube),
        ),
        const SizedBox(width: PianoSpacing.md),
        _SourceChip(
          label: 'Record',
          icon: Icons.mic,
          selected: selectedSource == ImportSource.recording,
          onTap: () => onChanged(ImportSource.recording),
        ),
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PianoRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PianoSpacing.lg,
          vertical: PianoSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.accent : colors.paper3,
          borderRadius: BorderRadius.circular(PianoRadius.md),
          border: Border.all(
            color: selected ? colors.accent : colors.rule,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? colors.accentInk : colors.ink,
            ),
            const SizedBox(width: PianoSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? colors.accentInk : colors.ink,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceInput extends StatelessWidget {
  const _SourceInput({
    required this.source,
    required this.youtubeController,
    required this.isRecording,
    required this.pickedFilePath,
    required this.recordedBytes,
    required this.onPickFile,
    required this.onStartRecording,
    required this.onStopRecording,
    this.youtubeError,
  });

  final ImportSource source;
  final TextEditingController youtubeController;
  final bool isRecording;
  final String? pickedFilePath;
  final Uint8List? recordedBytes;
  final VoidCallback onPickFile;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final String? youtubeError;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);

    return switch (source) {
      ImportSource.file => Column(
          children: [
            OutlinedButton.icon(
              onPressed: onPickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Pick Audio File'),
            ),
            if (pickedFilePath != null) ...[
              const SizedBox(height: PianoSpacing.sm),
              Text(
                'Selected: ${pickedFilePath!.split('/').last}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ImportSource.youtube => TextField(
          controller: youtubeController,
          decoration: InputDecoration(
            labelText: 'YouTube URL',
            hintText: 'Paste YouTube URL',
            prefixIcon: const Icon(Icons.link),
            errorText: youtubeError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PianoRadius.md),
            ),
          ),
          keyboardType: TextInputType.url,
        ),
      ImportSource.recording => MicPermissionGate(
          child: Column(
            children: [
              if (!isRecording) ...[
                FilledButton.icon(
                  onPressed: onStartRecording,
                  icon: const Icon(Icons.mic),
                  label: const Text('Start Recording'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.paper,
                  ),
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: onStopRecording,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Recording'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.accentInk,
                  ),
                ),
              ],
              if (recordedBytes != null && !isRecording) ...[
                const SizedBox(height: PianoSpacing.sm),
                Text(
                  'Recorded ${recordedBytes!.length} bytes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
    };
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.source,
    required this.youtubeUrl,
    required this.isRecording,
    required this.isSubmitting,
    required this.onPressed,
    required this.pickedFilePath,
    required this.recordedBytes,
  });

  final ImportSource source;
  final String youtubeUrl;
  final bool isRecording;
  final bool isSubmitting;
  final VoidCallback onPressed;
  final String? pickedFilePath;
  final Uint8List? recordedBytes;

  @override
  Widget build(BuildContext context) {
    bool canSubmit = false;

    switch (source) {
      case ImportSource.file:
        canSubmit = pickedFilePath != null;
        break;
      case ImportSource.youtube:
        canSubmit = youtubeUrl.trim().isNotEmpty;
        break;
      case ImportSource.recording:
        canSubmit = recordedBytes != null && !isRecording;
        break;
    }

    return FilledButton(
      onPressed: canSubmit && !isSubmitting ? onPressed : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      child: isSubmitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Submit'),
    );
  }
}

class _PollingStatus extends StatelessWidget {
  const _PollingStatus({required this.jobId, required this.status, required this.onCancel});

  final String jobId;
  final IngestionJobStatus? status;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: PianoSpacing.md),
        Text(
          '${_stageLabel(status)} (Job: ${jobId.length > 8 ? jobId.substring(0, 8) : jobId}...)',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: PianoSpacing.md),
        OutlinedButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  static String _stageLabel(IngestionJobStatus? status) {
    return switch (status) {
      null || IngestionJobStatus.queued => 'Queued...',
      IngestionJobStatus.downloading => 'Downloading audio...',
      IngestionJobStatus.transcribing => 'Transcribing...',
      IngestionJobStatus.done => 'Done',
      IngestionJobStatus.failed => 'Failed',
    };
  }
}