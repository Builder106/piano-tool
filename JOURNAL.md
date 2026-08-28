# Journal

A dated log of decisions and the reasoning behind them, especially the ones that
are not obvious from the code.

## 2026-08-17: UI revamp, phase 1 (visual foundation)

Branch `ui-revamp-foundation`, 13 commits. Spec in
`docs/specs/2026-08-17-ui-revamp-design.md`, plan in
`docs/plans/2026-08-17-ui-revamp-foundation.md`.

Delivered a token layer, a Material 3 theme, three bundled fonts, staff geometry
in staff-space units, a rewritten staff painter, a `StaffView`, and three golden
images. The tests went from 7 passing with 1 failing to 55 passing with none,
and `flutter analyze` dropped from 83 infos to 75.

### Why the app looked broken

The single screen was laid out for a wide desktop window and was running
portrait on a phone. The transport row hard-coded a 100px slider and a 200px
progress bar inside a `Row` with two `Spacer`s, which overflowed a 1080px screen
by 211px. Three `AppBar` actions squeezed the title to `"C ..."`. Sixty-one keys
at a fixed 24px needed 1464px. A 70/30 flex split gave the staff a thousand
pixels of column for four hundred of content.

### Decisions worth remembering

**The README does not describe this codebase.** It documents a level format with
a nested `pitch` object and a `clef` field. The real `LevelNote` uses a flat
`midiNote` int, and there is no clef type anywhere in `lib/`. `LevelModel`
carries `clefOctave` and `transpose` instead. The spec was written partly from
the README and inherited the error, which surfaced only when a task tried to
import `Clef`. Read the models, not the README. The README still needs fixing.

**`Clef` is a UI-layer concept, for now.** Defined in
`lib/ui/staff/staff_geometry.dart` because the models have no clef. `StaffView`
takes a list of systems, each naming its own clef, so the caller decides whether
to draw one staff or two. Moving it into the level format belongs with the
practice screen that would read it.

**`NoteState` has six values, not four.** `upcoming, active, hitPerfect,
hitGood, hitOkay, missed`. All three hit gradations render as the same filled
notehead. Encoding hit quality visually is a scoring-feedback decision nobody has
made yet, and inventing one during a layout fix would have been scope creep.

**Note state is a shape before it is a colour.** Filled, hollow, ringed, or
struck through. The previous build distinguished hit from missed only by green
against red, which is invisible to red-green colour blindness. Filled against
hollow noteheads is real notation, so the fix costs nothing and reads as more
musical rather than less.

**Fonts are bundled, not fetched.** `google_fonts` was removed. Runtime fetching
made golden tests depend on the network and left the app with no offline
guarantee. Cormorant Garamond and IBM Plex Sans are variable fonts registered
with one asset each and no `weight:` keys, so weight is driven by
`fontVariations` on the `wght` axis. An earlier attempt registered the same
variable font under five static-looking filenames, which meant every weight
resolved to identical bytes and there was no weight contrast at all.

**Clefs come from Bravura.** Unicode `U+1D11E` and `U+1D122` render from
whatever font the OS supplies, land in the wrong vertical position, and are
missing entirely on some Android builds. Bravura is the SMuFL reference font and
is free under the OFL. This is what the empty `assets/fonts/` entry in
`pubspec.yaml` had always been declared for.

**Everything on the staff is sized in staff-spaces.** One space is a quarter of
the staff height. Noteheads are one space, the time signature is four, stems are
about two. This is what makes a grand staff free: halve the band and every glyph
scales with it, with no second code path.

**`test/flutter_test_config.dart` is load-bearing.** Flutter test harnesses do
not load fonts declared in `pubspec.yaml`. Without that file, text renders as
tofu boxes and the golden images bake missing glyphs in as expected output. The
first set of goldens passed 51 of 51 tests while showing black rectangles where
the clef and time signature belong.

**Golden tests are skipped off Linux.** Font rasterisation differs by host and
the default comparator is byte-exact, so the images are generated and verified
on the Linux VM. The two non-golden layout tests still run everywhere.

### The bug that came back

The original overflow was a content-derived size combined with a fixed offset.
The rewritten painter reintroduced exactly that shape: the clef and time
signature were sized in staff-spaces, which scale with staff height, while notes
started at a fixed `leadingBeats * pixelsPerBeat`. The two agreed on a short
staff and collided on a tall one, putting the time signature on top of the first
two notes. `leadingBeats` is gone and the note origin now derives from the
header width, so there is only one way to express the offset.

### What the tests did not catch

Both visual defects in the golden images, the tofu glyphs and the collision,
passed every test. A golden that captures a broken rendering locks the defect in
as expected output, so every later run confirms the bug rather than finding it.
Look at the images.

### Deliberately left for phase 2

The five screens and routing, `ProgressRepository` on `shared_preferences`, the
Riverpod wrapping of `StageEngine`, the practice-screen layout with its 60dp
control column, the keyboard rewrite as visualization only, the
microphone-permission state, wiring the speed slider to
`StageEngine.setPlaybackSpeed`, and giving Stop and Replay distinct behaviour.

Correction to an earlier note above: `setPlaybackSpeed` does not work and never
did. Its body is two comments, it ignores its argument, and `_config` is final,
so the playback tick reads a speed that is permanently 1.0. Making the slider
work needs a small engine change, not just a UI connection.

Also carried forward: the brace on the grand staff, which is unreachable until
the level format carries a second staff; time-signature digits drawn in Cormorant
rather than Bravura's own glyphs; and `lib/ui/game/game_screen.dart`, which is
still the pre-revamp screen and is replaced wholesale in phase 2.

## 2026-08-18: UI revamp, phase 2 (the practice screen)

Branch `readme-and-phase-2`, 8 tasks, each reviewed and merged individually
before this final whole-branch pass. Replaced the pre-revamp single-screen
prototype with `PracticeScreen` and the Riverpod glue in
`lib/ui/practice/stage_controller.dart`, deleted the dead JSON level pipeline
and the legacy screen it fed, and closed out the phase-1 punch list: the
speed control works, Stop and Replay are distinct, and a denied microphone
gets a real UI state.

### `stageControllerProvider` is not `.autoDispose`, on purpose

This came up during task review twice and was deferred both times. Nothing
in the app navigates between stages yet -- `PracticeScreen` is reachable only
by passing a `stageId` directly, with no router in front of it -- so there is
no point in the app's lifecycle where a stage's controller should actually be
torn down and rebuilt. Making the provider `.autoDispose` now would change
what `container.read(stageControllerProvider(id))` means across a rebuild
(a fresh controller instead of the same one) for a scenario that cannot
happen yet, and would need to be revisited anyway once Plan 3's router
exists and defines when a stage screen actually unmounts for good. Decide it
there, with a real navigation flow to test it against, not here against a
hypothetical one.

### One audio engine, not one per consumer

`audioEngineProvider` is a single `Provider<AudioEngine>` that both
`audioGrantedProvider` (permission and the initial `start()`) and
`audioPitchStreamProvider` (the live pitch stream) read from. Two separate
engines were considered and rejected: opening the microphone twice is worse
than opening it once, and a retry-after-denial flow only works if the same
engine instance that failed to initialize is the one asked to try again. A
second engine created fresh at retry time would not carry that failure
state, and the permission gate would have no way to tell whether a retry was
really retrying anything.

### Two tasks were added mid-plan, not in the original scope

**Task 7, `StageEngine.setPlaybackSpeed`.** The phase-1 journal already
corrected the record on this once: the spec had claimed the speed slider
just needed wiring to an engine method that already worked. It didn't --
`setPlaybackSpeed` was two comments and an ignored argument, and `_config`
being `final` meant the playback tick could never see a changed speed. The
UI-only task became an engine task once that was discovered.

**Task 8, the staff height cap and scroll.** Ninety-two passing tests gave no
signal that anything was wrong. A rendered screenshot did: on a tall band the
staff overflowed its own container, because nothing had ever capped how much
of the band the staff geometry was allowed to claim. `staffGeometryForBand`
in `lib/ui/staff/staff_geometry.dart` and `kDefaultMaxStaffHeight` came out of
that screenshot, not out of a failing test. The lesson carried over from
phase 1 held again: a passing test suite is not evidence the thing looks
right, only that it does what the tests happened to check.

### Left from this final review for Plan 3

Test coverage for the scroll path (no pixel or integration test), a
practice-screen golden, and `main.dart`. `seekTo` has no caller from the UI.
Stop and Replay both rewind to the start of the *transport*, so the
difference between them is only in what they do to playback state, not to
position on screen -- worth revisiting once there is a results screen to
navigate back from. `onPitch`'s volume/confidence gate does not match
`StageEngine.processPitchEvent`'s own gate, which is a duplicated-condition
risk rather than a known bug. The note-index duplication between the
controller and the engine, and the fire-and-forget `record()` /
`setLastPlayed()` calls on `ProgressRepository`, are both still there.
`test/_startup_screenshot_test.dart` is an untracked scratch file, kept
deliberately; leave it alone.

## 2026-08-28: finish the piano-tool practice flow

The `piano-tool` branch had the practice loop but no results route. It now
records completion metrics, routes to a results screen, and lets the learner
replay the stage or return to the level list.

Persisted imported levels are hydrated before the level list renders, and save
and delete actions invalidate that catalog after changing storage. The branch
also declares the Flutter packages already used by its source and keeps its
Vercel deployment gate open only for the `piano-tool` branch.

Remote verification passed with 166 Flutter tests and 39 backend tests.
`flutter analyze --no-fatal-infos` reports 61 performance infos and no
warnings.

## 2026-08-28: keep the Vercel backend under its function limit

The first successful Vercel dependency install still produced a 522.97 MB
Python function bundle, over Vercel's 500 MB limit. The deployed path uses
basic-pitch's ONNX backend; it does not need scikit-learn or uvicorn's optional
server extensions. Production installation therefore uses plain `uvicorn`,
removes scikit-learn after dependency resolution, and excludes backend tests
and documentation from the function bundle. The full backend test stack
remains in `backend/requirements.txt`.

The production-shaped Python 3.12 environment reached 480,344 KB, and the
FastAPI and transcription imports succeeded without scikit-learn. The full
backend suite had already passed with that package removed: 39 tests passed
with three existing warnings.
