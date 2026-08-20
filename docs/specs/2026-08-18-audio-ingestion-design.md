# Audio ingestion design

**Goal:** let a user turn a piano recording, a YouTube link, or a live recording into a playable level, without leaving the app.

**Status:** design, not yet built. This is the first of two ingestion subsystems (the other is OMR for sheet music/photos, deferred — see "Relationship to OMR" below).

## Why this exists

Piano-Tool currently ships three hardcoded practice levels. There is no way to practice a specific piece unless someone hand-encodes it into `LevelModel` first. This spec adds a pipeline that takes real audio in and produces a `LevelModel` out, so the content a learner wants to practice is whatever they can play a recording of.

## Feasibility, already verified

Before this spec was written, two throwaway probes ran on `ampere-dev`:

- `basic-pitch` (Spotify's polyphonic piano transcription model, ONNX backend, no TensorFlow) transcribed a 3:38 public-domain piano recording (Satie's Gnossienne No. 1) in 17 seconds on CPU. The output's first notes (`F2, F3, C4, C5, G#3...`) match the piece's actual opening bass ostinato and melodic figure.
- Separately, an OMR probe (Audiveris, built from source, since no aarch64 Linux binary exists) transcribed a real scanned page of Beethoven's Für Elise into MusicXML with recognizably correct melody and bass, with one identifiable accidental-reading error.

Both probes are real evidence the underlying transcription step works well enough to build on. Neither probe's code is part of this spec; this document designs the real pipeline from scratch.

## Relationship to OMR

Audio ingestion and OMR (photographed/scanned sheet music) are two independent subsystems that happen to produce the same output type (`LevelModel`). They were decomposed at brainstorming time rather than designed together, because their technology, failure modes, and hosting requirements differ enough that a combined design would blur both. This spec covers audio only. OMR gets its own spec later, informed by whatever this pipeline's review-and-storage pieces teach us.

YouTube ingestion is not a third subsystem. Once a video's audio is extracted, it's the same transcription pipeline as any other audio input — this spec treats it as one more ingestion source, not a separate pipeline.

## Scope for this version

In scope:

- Ingest audio from an uploaded file, a YouTube link, or a recording made in the app.
- Transcribe piano-dominant audio into notes.
- Estimate tempo and quantize note timing onto a beat grid, producing a `LevelModel`.
- A review step: play the transcription back before it's saved.
- Store imported levels alongside (not replacing) the three built-in stages.

Explicitly out of scope, deferred to later work:

- **Source separation** for audio where piano isn't the dominant or only instrument. `basic-pitch` is validated for piano-forward material; mixed tracks are accepted and transcribed as-is, and will usually produce a visibly bad result that the review step exists to catch. Running separation (e.g. Demucs) first is real future work, not attempted here.
- **Note-level editing.** The review step is playback-and-decide (save or discard), not a piano-roll editor. If correction turns out to be needed often, that's its own project.
- **Meter detection.** Every imported level is quantized as 4/4. A different time signature will produce visibly wrong bar lines in review; detecting meter automatically is not attempted here.
- **A full level-select screen.** This spec's app-side work adds a minimal list of imported levels, not the multi-screen home/level-select/results/settings navigation from the original UI-revamp spec (still Plan 3's job, and still not started).

## Architecture

Three new pieces:

1. **A backend service**, Python, hosted persistently on `ampere-dev`. It owns audio acquisition (upload handling, YouTube extraction via `yt-dlp`), transcription (`basic-pitch`), and beat quantization. This is a genuine change to what `ampere-dev` is: previously a build-and-verify box only, now also a small always-on service. That distinction should be reflected wherever the VM's role is documented once this is built.
2. **An `IngestionRepository`** in the Flutter app, parallel to the existing `ProgressRepository`/`LevelRepository`. It talks to the backend over HTTP and persists finished levels locally via `shared_preferences`, following the same pattern `ProgressRepository` already established.
3. **Two new screens**: `ImportScreen` (pick a source, submit it) and `ReviewScreen` (play the result back, save or discard).

### Why a backend instead of on-device inference

`basic-pitch` and `yt-dlp` are both Python-native. Running transcription on-device would mean bridging Flutter to a mobile ONNX runtime, packaging the model into the app, and growing app size — real plumbing with no upside for a personal-use app that already has network access. A backend also keeps the door open for source separation later, which is heavy enough that on-device was never realistic for it. The cost is that transcription requires network access and the backend is now something to operate, not just code that ships in the app bundle.

### Why an async job model instead of a synchronous request

A real transcription job is a YouTube download (variable, sometimes 10-30s) plus `basic-pitch` inference (roughly 5-10% of audio duration on this VM's CPU, per the probe). Holding one HTTP request open for up to a minute on a mobile connection is fragile. Instead:

```
POST /jobs
  body: { source: "upload" | "youtube", audio?: <file>, youtube_url?: string }
  → 202 { job_id, status: "queued" }

GET /jobs/{job_id}
  → 200 { status: "queued" | "downloading" | "transcribing" | "done" | "failed",
          error?: string,      // present only when status is "failed"
          level?: LevelModel } // present only when status is "done"

DELETE /jobs/{job_id}
  → discards a job the app no longer needs (cancels if still running)
```

The app polls `GET /jobs/{id}` every 2-3 seconds while a job is in flight. Jobs run against an in-process background queue on the backend — no external queue infrastructure, since this is a single-user service with modest concurrency needs.

Failure is surfaced as data (`status: "failed"`, `error: "<plain-English reason>"`), not as an HTTP error code, because the app needs to show the user *why* a job failed, not just that it did.

### On `yt-dlp` and YouTube's Terms of Service

`yt-dlp` downloads audio in a way that YouTube's Terms of Service generally don't authorize outside their own official offline features. It's extremely widely used for personal, non-commercial purposes, and this pipeline stays entirely inside a personal-use app run by and for one person, with no redistribution of downloaded audio. That's a real distinction from what the ToS is written to prevent, but it doesn't make the download itself authorized. Worth having in view if this ever stops being a single-user tool.

## Pipeline

1. **Ingest.** Upload, YouTube URL, or an in-app recording — all three normalize to a local audio file on the backend.
2. **Acquire audio.** For YouTube, `yt-dlp` extracts the best audio stream. Upload and recording are already local files.
3. **Reject early if obviously bad**, before spending inference time: audio longer than a duration cap (10 minutes — long enough for most pieces, short enough to stop a podcast or full concert link from burning a job's worth of compute for nothing), or a YouTube extraction failure (private/removed/geo-blocked video, or `yt-dlp` breaking against a YouTube-side change, which happens periodically and is an accepted operational cost of depending on it).
4. **Transcribe.** `basic-pitch`, ONNX backend, as verified in the probe. Produces raw note events: pitch, onset, offset, velocity, all in seconds.
5. **Reject if the transcription is near-empty** — silence, non-music audio, or a transcription that clearly failed produces close to zero notes. Fail the job here rather than saving an empty level.
6. **Quantize to beats.** Estimate tempo via `librosa.beat.beat_track`, snap note onsets to the nearest 16th-note position at that tempo, assume 4/4 (see "Scope," meter detection is deferred). This step turns "notes at second 1.27, 1.52, 1.81..." into the `startBeat`/`durationBeats` values `LevelModel` actually needs.
7. **Package as a `LevelModel`.** Reuses the existing type in `lib/models/level_models.dart` exactly — no new level format.
8. **Return to the app**, where the review step plays it back through the existing `PracticeScreen`/`StaffView` before it's saved.

## App-side additions

- **`lib/data/ingestion_repository.dart`** — `IngestionRepository`, exposing `submitUpload(File)`, `submitYoutubeUrl(String)`, `pollJob(String jobId)`, and `saveLevel(LevelModel)` / `listImportedLevels()`. Persists via `shared_preferences` under its own key namespace, separate from `ProgressRepository`'s keys.
- **`lib/ui/import/import_screen.dart`** — source picker (file, YouTube URL field, record button reusing the existing mic-permission gate), submits a job, shows live status while polling.
- **`lib/ui/import/review_screen.dart`** — plays the transcribed level back in a read-only preview via the existing staff/keyboard views, with Save and Discard actions.
- **`LevelRepository`** gains a light extension: alongside the three built-in stages, it lists whatever `IngestionRepository` has saved. Since there's currently no screen that lists stages at all, this forces a minimal list screen into existence as a side effect — not the full level-select from the original UI-revamp spec, just enough to see and open an imported level.

## Error handling

| Failure | Where caught | User sees |
|---|---|---|
| Audio too long | Step 3, before download/inference | "That's longer than 10 minutes — try a shorter clip." |
| YouTube video unavailable | Step 3, during extraction | "Couldn't download that video" (with the underlying reason if `yt-dlp` provides one) |
| Silent/non-music/corrupted audio | Step 5, after transcription | "Didn't find any notes in that audio" |
| Garbled transcription (e.g. non-piano-dominant track) | Not caught programmatically | Shown in the review step; user discards it |
| Backend unreachable | App-side, on job submission | Standard network-error handling — retry, or fall back to nothing (no offline queue for v1) |

## Testing

Per the project's CI-tier convention: this adds a new backend API surface, so it gets integration tests covering the job lifecycle (submit → poll → done, submit → poll → failed, each rejection path in the pipeline). The beat-quantization step gets unit tests specifically, since it's the one genuinely new algorithm in this pipeline and the kind of code that can silently produce a plausible-looking wrong answer.

App-side: unit tests for `IngestionRepository` against a mocked backend (following the existing pattern of narrow, mockable repositories), widget tests for `ImportScreen` and `ReviewScreen`.

No E2E tier for this version — there's no CI runner that can reasonably drive a real YouTube download, and the backend isn't part of the Flutter app's own test suite or build.

## Open questions carried into the implementation plan, not resolved here

- Exact backend framework choice (FastAPI is the likely default given the Python dependency set, but not committed in this spec).
- Whether the backend needs auth at all, given it's a single-user service reachable only from one person's phone — likely yes in some minimal form once it's reachable from outside `ampere-dev`'s local network, but the threat model needs a decision before the app talks to it over anything but a local/VPN connection.
- Whether `ampere-dev`'s existing role (build-and-verify box, documented in CLAUDE.md and `vm-builds`) needs updating once it's also hosting a persistent service.
