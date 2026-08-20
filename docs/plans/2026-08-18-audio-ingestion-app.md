# Audio Ingestion App-Side Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flutter app-side integration for the audio ingestion backend. Adds `IngestionRepository`, `ImportScreen`, `ReviewScreen`, and extends `LevelRepository` to list imported levels alongside built-in stages.

**Backend:** Already built and tested at `backend/` with API:
- `POST /jobs` → 202 { job_id, status: "queued" }
- `GET /jobs/{job_id}` → 200 { status, error?, level? }
- `DELETE /jobs/{job_id}` → 204

**Tech Stack:** Flutter, Riverpod, `shared_preferences`, `http`, `file_picker`, `record` (for in-app recording), `go_router` (for minimal navigation).

**Global Constraints:**
- Builds and tests run on `ampere-dev` VM only via `verify-on-vm`. Never run Flutter commands locally.
- Follow existing patterns: `ProgressRepository` for `shared_preferences` persistence, Riverpod providers, freezed models.
- Backend base URL is configurable via `--dart-define=INGESTION_API_BASE_URL` (defaults to `http://ampere-dev.local:8000` for local dev).
- No E2E tests — backend isn't part of Flutter test suite, and CI can't drive real YouTube downloads.

---

### Task 1: IngestionRepository

**Files:**
- Create: `lib/data/ingestion_repository.dart`
- Create: `lib/data/ingestion_repository_test.dart`

**Interfaces:**
- Consumes: HTTP client, `shared_preferences`
- Produces: `IngestionRepository` class with:
  - `submitUpload(File file) → Future<String jobId>`
  - `submitYoutubeUrl(String url) → Future<String jobId>`
  - `submitRecording(Uint8List audioBytes) → Future<String jobId>`
  - `pollJob(String jobId) → Future<JobStatus>` (status, error, level?)
  - `saveLevel(LevelModel level) → Future<void>`
  - `listImportedLevels() → Future<List<LevelModel>>`
  - `deleteImportedLevel(String levelId) → Future<void>`

**Storage:** `shared_preferences` under key prefix `ingestion.` — separate from `ProgressRepository`'s `progress.` namespace.

- [ ] **Step 1: Write the failing test**
- [ ] **Step 2: Run it and confirm it fails** (`verify-on-vm "<repo>" "flutter test test/data/ingestion_repository_test.dart"`)
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run it and confirm it passes**
- [ ] **Step 5: Commit**

---

### Task 2: ImportScreen

**Files:**
- Create: `lib/ui/import/import_screen.dart`
- Create: `lib/ui/import/import_screen_test.dart`

**Interfaces:**
- Consumes: `IngestionRepository`, `MicPermissionGate` (existing), Riverpod
- Produces: `ImportScreen` widget with:
  - Source picker: File upload (via `file_picker`), YouTube URL text field, Record button (reuses existing mic gate)
  - Job submission → shows polling status (queued → downloading → transcribing → done/failed)
  - On success: navigate to `ReviewScreen` with the `LevelModel`
  - On failure: show error message with retry option

- [ ] **Step 1: Write the failing test**
- [ ] **Step 2: Run it and confirm it fails**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run it and confirm it passes**
- [ ] **Step 5: Commit**

---

### Task 3: ReviewScreen

**Files:**
- Create: `lib/ui/import/review_screen.dart`
- Create: `lib/ui/import/review_screen_test.dart`

**Interfaces:**
- Consumes: `LevelModel` (passed via route), `IngestionRepository` (for save/discard)
- Produces: `ReviewScreen` widget with:
  - Read-only preview using existing `StaffView` + `PianoKeyboardView` (no `StageEngine`, no scoring)
  - Play/pause transport (reuse `TransportColumn` but read-only)
  - Speed control (wired to a local playback controller)
  - Save button → calls `IngestionRepository.saveLevel()`, then navigates to level list
  - Discard button → returns to `ImportScreen`

- [ ] **Step 1: Write the failing test**
- [ ] **Step 2: Run it and confirm it fails**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run it and confirm it passes**
- [ ] **Step 5: Commit**

---

### Task 4: Extend LevelRepository + Minimal Level List Screen

**Files:**
- Modify: `lib/data/level_repository.dart`
- Create: `lib/ui/levels/level_list_screen.dart`
- Create: `lib/ui/levels/level_list_screen_test.dart`

**Interfaces:**
- `LevelRepository` gains:
  - `addImportedLevel(LevelModel level)` — adds to internal maps
  - `removeImportedLevel(String levelId)` — removes from internal maps
  - `getAllLevels()` — now returns built-in + imported
  - `getAllStages()` — now includes stages wrapping imported levels (auto-generate `StageModel` with `Difficulty.beginner`, order after built-ins)

- `LevelListScreen`:
  - Simple list: built-in stages first (in order), then imported levels (newest first)
  - Tap → navigates to `PracticeScreen` with that stage/level ID
  - Long-press or menu on imported → delete confirmation

- [ ] **Step 1: Write the failing test**
- [ ] **Step 2: Run it and confirm it fails**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run it and confirm it passes**
- [ ] **Step 5: Commit**

---

### Task 5: Wiring and Routing

**Files:**
- Modify: `lib/main.dart` (add `go_router`)
- Create: `lib/app_router.dart`

**Interfaces:**
- Routes:
  - `/` → `LevelListScreen` (new home)
  - `/import` → `ImportScreen`
  - `/review?jobId=...` → `ReviewScreen`
  - `/practice/:stageId` → `PracticeScreen` (existing)

- Riverpod providers for `IngestionRepository` and HTTP client with base URL from dart-define.

- [ ] **Step 1: Write the failing test**
- [ ] **Step 2: Run it and confirm it fails**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run it and confirm it passes**
- [ ] **Step 5: Commit**

---

### Task 6: IngestionRepository Unit Tests (Mocked Backend)

**Files:**
- Already created in Task 1: `lib/data/ingestion_repository_test.dart`

**Coverage:**
- Submit upload/youtube/recording → returns jobId
- Poll job → returns correct status/error/level
- Save level → persists and appears in listImportedLevels
- Delete level → removed from list
- Network errors → appropriate exceptions

- [ ] **Step 1: Write the failing tests** (if not done in Task 1)
- [ ] **Step 2: Run and confirm they fail**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run and confirm they pass**
- [ ] **Step 5: Commit** (already committed with Task 1)

---

### Task 7: Widget Tests

**Files:**
- Already created in Tasks 2-4: `import_screen_test.dart`, `review_screen_test.dart`, `level_list_screen_test.dart`

**Coverage:**
- ImportScreen: source picker renders, file pick triggers, YouTube field validates, record button gated by mic permission
- ReviewScreen: staff renders level, transport plays/pauses, save/discard navigate correctly
- LevelListScreen: built-in + imported stages shown, tap navigates, delete works

- [ ] **Step 1: Write the failing tests**
- [ ] **Step 2: Run and confirm they fail**
- [ ] **Step 3: Implement**
- [ ] **Step 4: Run and confirm they pass**
- [ ] **Step 5: Commit** (already committed with respective tasks)

---

### Task 8: Full Suite Verification

**Commands:**
```bash
verify-on-vm "<repo>" "flutter test"
verify-on-vm "<repo>" "flutter analyze --no-fatal-infos"
```

**Expected:** All 119+ tests pass, analyze reports ≤64 infos (no new issues introduced).

- [ ] **Step 1: Run full test suite**
- [ ] **Step 2: Run analyze**
- [ ] **Step 3: Commit any final fixes**

---

## After this plan

The app will have a complete ingestion flow: user opens app → sees level list (built-in + imported) → taps Import → picks file/YouTube/record → submits → polls backend → reviews transcription → saves or discards → saved level appears in list → tap to practice.

The three deferred items from the spec (source separation, note-level editing, meter detection) remain out of scope. The full home/level-select/results/settings navigation from the original UI-revamp spec is still Plan 3's job.