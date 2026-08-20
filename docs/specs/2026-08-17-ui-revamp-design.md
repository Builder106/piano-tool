# Piano-Tool UI revamp: design

Date: 2026-08-17
Status: approved, ready for implementation planning

## Why

The app ships one screen, and that screen was laid out for a wide desktop window
while running portrait on a phone. Every symptom traces back to that mismatch.

The transport row hard-codes a 100px slider and a 200px progress bar inside a
`Row` with two `Spacer`s. On a 1080px-wide screen that overflows by 211px, and
Flutter paints its yellow-and-black stripe over the UI
(`lib/ui/game/game_screen.dart:345-405`). Three `AppBar` actions squeeze the
title down to `"C ..."` (`lib/ui/game/game_screen.dart:274-317`). Sixty-one keys
at a fixed 24px each need 1464px on a 1080px screen
(`lib/ui/keyboard/piano_keyboard.dart:60`); it scrolls, but nothing ever scrolls
it to the octave in play. And a 70/30 flex split hands the staff roughly 1000px
of column for 440px of content, which is the large dead band on screen
(`lib/ui/game/game_screen.dart:322`).

Several controls are inert. The speed slider does nothing, and its label returns
`"1.0x"` from both branches of a ternary
(`lib/ui/game/game_screen.dart:378-391`). Stop and Replay both call `reset()`.
A denied microphone permission has no UI at all, because `_initAudioEngine`
fails silently (`lib/ui/game/game_screen.dart:54-74`). Meanwhile `setState`
fires on every `playbackPosition` event and again inside `_updateActiveNotes`,
rebuilding the whole tree every frame.

One problem is more serious than the layout. Note state is encoded only as green
against red, which is invisible to red-green colour blindness, roughly 1 in 12
men.

## What is not changing

`models/`, `data/`, `audio/`, and `engine/` are independent of the UI and carry
the existing test coverage. `StageEngine` emits a clean event stream and its
event model is sound. The problem is how the UI consumes events, not how the
engine emits them.

The line sits at `lib/ui/`. Everything below it stays, and the existing tests
stay green throughout.

## Decisions

| Decision | Choice |
| --- | --- |
| Form factor | Phone, landscape-locked, whole app |
| Scope | Home, level select, practice, results, settings |
| Approach | Rebuild `lib/ui/` on Riverpod; engine untouched |
| Routing | Plain `Navigator` with named routes, no `go_router` |
| Persistence | `shared_preferences` behind one `ProgressRepository` |
| Keyboard | Visualization only; tapping does not score |
| Staff | Renderer draws what the level declares: one staff or two |
| Theme | Material 3 substrate, custom token layer, light and dark |

Landscape lock covers the whole app, not just practice. Locking a single screen
means the OS rotates the user in and out as they navigate, which feels broken.
Home and level select are therefore landscape layouts, built from horizontal
card rows rather than vertical lists.

Making the keyboard visualization-only is what frees the layout. Keys no longer
need touch-target width, so all 36 white keys fit across a landscape screen at
roughly 21dp each and the keyboard stops needing to scroll at all. It also
removes the fake `PitchEvent` that touch input currently fabricates and feeds to
the engine as if it were played audio
(`lib/ui/game/game_screen.dart:235-254`).

## Design system

Authored in OKLCH so the lightness relationships stay honest, then shipped as
sRGB `Color` constants in `lib/ui/theme/tokens.dart` with the OKLCH source kept
in comments.

The identity is a recital hall: a warm ground with a cool action colour. The
vibe names two hues, so the warm one (brass, 72°) tints every neutral and the
cool one (ink blue, 262°) is the single accent. Hue never changes between
themes. Only lightness and chroma move.

### Light

| Token | OKLCH | sRGB | Contrast on paper |
| --- | --- | --- | --- |
| `paper` | `100% 0 0` | `#FFFFFF` | n/a |
| `paper2` | `97.5% 0.006 72` | `#F9F6F2` | n/a |
| `paper3` | `94.5% 0.010 72` | `#F1ECE6` | n/a |
| `ink` | `20% 0.012 68` | `#1A1510` | 18.12:1 |
| `ink2` | `38% 0.012 68` | `#47413C` | 10.05:1 |
| `staff` | `58% 0.014 72` | `#807971` | 4.29:1 |
| `rule` | `82% 0.012 72` | `#C9C3BC` | n/a |
| `rule2` | `90% 0.010 72` | `#E2DDD7` | n/a |
| `muted` | `50% 0.012 68` | `#68625C` | 6.02:1 |
| `accent` | `48% 0.16 262` | `#2757B6` | 6.72:1 |
| `accentInk` | `99% 0.004 72` | `#FDFBF9` | 6.51:1 on accent |
| `focus` | `52% 0.20 262` | `#1F5ED9` | n/a |
| `success` | `48% 0.13 150` | `#067132` | 6.15:1 |
| `error` | `52% 0.17 25` | `#B63132` | 6.04:1 |

### Dark

| Token | OKLCH | sRGB | Contrast on paper |
| --- | --- | --- | --- |
| `paper` | `16% 0.014 72` | `#110C07` | n/a |
| `paper2` | `20% 0.016 72` | `#1B150E` | n/a |
| `paper3` | `24% 0.016 72` | `#241E17` | n/a |
| `ink` | `93% 0.010 72` | `#ECE7E1` | 15.83:1 |
| `ink2` | `74% 0.010 72` | `#AFAAA4` | 8.44:1 |
| `staff` | `56% 0.014 72` | `#7A736C` | 4.17:1 |
| `rule` | `40% 0.014 72` | `#4D4740` | n/a |
| `rule2` | `30% 0.012 72` | `#322D27` | n/a |
| `muted` | `62% 0.012 68` | `#8B857F` | 5.34:1 |
| `accent` | `66% 0.13 262` | `#6591E1` | 6.20:1 |
| `accentInk` | `18% 0.012 68` | `#15110C` | 5.99:1 on accent |
| `focus` | `72% 0.17 262` | `#68A1FF` | n/a |
| `success` | `68% 0.12 150` | `#5DAD70` | 7.11:1 |
| `error` | `64% 0.15 25` | `#D8625C` | 5.39:1 |

Paper is true white, so the warmth has to live somewhere else. It moved into the
rules, the inks, and the two elevated surfaces. `staff` earns its own token
because staff lines are content rather than chrome, and reusing the divider
`rule` made them nearly invisible on white. It is the one token that holds
roughly the same lightness in both themes, since the staff should read equally
in either.

### Type

Two families, not three.

Cormorant Garamond 600/700, roman only, carries the display role: level titles,
the results headline, the app wordmark. It never appears below 20px, where its
low x-height would hurt legibility.

IBM Plex Sans 400/500/600 carries everything else, and every metric sets
`FontFeature.tabularFigures()` so numbers hold their columns as they change.

Both are bundled under `assets/fonts/` rather than pulled from the
`google_fonts` package, so there is no network fetch on first launch. A mono
outlier for the metrics was considered and cut: Plex Sans has real tabular
figures, so a third bundled font buys nothing.

This replaces `GoogleFonts.interTextTheme()` (`lib/main.dart:25` and `:34`).
Inter is the most on-distribution font available and reads as un-chosen.

### Music font

Clefs must not be Unicode characters. `U+1D11E` and `U+1D122` render from
whatever font the OS happens to supply, their vertical metrics do not land where
engraving expects, and on some Android builds the glyph is missing entirely and
draws as a blank box.

Bundle Bravura, the SMuFL reference font, free under the OFL. This is also what
the empty `assets/fonts/` entry in `pubspec.yaml` was always for. That directory
is declared but does not exist on disk, which will break the build as soon as
anything relies on it.

### Spacing, motion, depth

A 4pt scale named by role, from `space2xs` (4) through `space3xl` (96).

Depth comes from weight and lightness, never elevation. No `Card` shadows: on
the dark ground a Material shadow turns into a glow.

There is one motion moment, a 120ms notehead tick on hit, animating `transform`
and `opacity` only. The playhead and progress bar are functional and keep
running under reduced motion. Nothing responds to hover, because this is a touch
device.

Accent stays under 5% of any screen. Ink blue appears in exactly three roles:
the playhead, the note currently due, and the primary action.

## Note state is a shape first and a colour second

This is the central idea, and the fix for the colour-blindness problem.

| State | Notehead | Colour |
| --- | --- | --- |
| Upcoming | Hollow, hairline | `muted` |
| Due now | Filled, with a ring | `accent` |
| Hit | Filled solid | `success` |
| Missed | Hollow, struck through with a slash | `error` |

Filled against hollow noteheads is real notation, so the fix costs nothing and
reads as more musical rather than less. The same principle extends to the
keyboard, where a due key is marked by ground and a played key by fill.

## Screens

Five routes on a plain `Navigator`, in `lib/ui/router.dart`.

| Route | Screen | Notes |
| --- | --- | --- |
| `/` | Home | Continue card, plus entries to Levels and Settings |
| `/levels` | Level select | Horizontal cards showing best accuracy, best score, completion |
| `/practice` | Practice | Takes a `stageId`, replacing the hardcoded `order == 1` lookup |
| `/results` | Results | Replaces the `AlertDialog`; beats-previous-best, Retry, Next |
| `/settings` | Settings | Tolerance, default speed, theme mode, mic permission status |

Results replaces practice on the stack rather than stacking above it, so Back
from results returns to level select instead of dropping the user into a
finished stage.

### Practice layout

A left control column, with everything else stacked beside it.

| Region | Sizing | Rationale |
| --- | --- | --- |
| Control column | 60dp fixed width | Holds icon buttons at a 48dp touch target, and the horizontal axis has slack |
| HUD row | 44dp, title `Expanded` with ellipsis | The title yields instead of the metrics, so no more `"C ..."` |
| Staff | `Expanded` | Takes the remainder, growing on larger screens instead of leaving a dead band |
| Keyboard | `clamp(64, 21%, 88)dp`, key width = available / 36 | All 61 keys fit without scrolling |

No fixed-width child sits inside the transport. The one unavoidable fixed size
is a width on a horizontal axis that has room, which is what structurally
prevents the 211px class of bug from coming back.

## Staff renderer

Everything on the staff is sized in staff-spaces derived from the staff height,
rather than as a fraction of the band. One space is a quarter of the staff.
Noteheads are one space tall and about 1.3 wide, the time signature is four
spaces, and stems run roughly two.

That unit is what makes the grand staff free. Halve the band and every glyph
scales with it, with no separate sizing path.

The renderer draws whatever it is handed: a list of systems, each naming its own
clef. One system draws one staff, two draw a braced grand staff.

A correction to an earlier draft of this section, found while planning. It said
a level "declares one `clef`". It does not. `lib/models/level_models.dart` has
no clef type at all; `LevelModel` carries `clefOctave` (an int) and `transpose`,
and the current painter hardcodes a treble clef. The README documents a level
format that does not match the models either, and that README is where the wrong
claim came from.

So `Clef` is introduced as a UI-layer rendering concept, and the caller decides
which systems to draw. Adding a `clef` field to the level format belongs with
the practice screen that would read it, in the second phase of work.
`twinkle_twinkle.json` keeps working untouched either way.

Stems are drawn as siblings of the notehead, never as children, so they stay
vertical instead of inheriting the notehead's rotation. Treble stems hang down
from the left of the head, and bass stems rise from the right.

## State and data

`StageEngine` gets wrapped in a Riverpod notifier that exposes narrow slices, so
widgets watch only what they need instead of rebuilding the tree on every
playback tick. That is the fix for the current per-frame `setState`.

`ProgressRepository` sits over `shared_preferences` and stores best score, best
accuracy, and completion per level. No accounts, no network, and deliberately no
swappable-backend abstraction, since local-only was the decision and a
repository interface is enough of a seam if that ever changes.

Three things get fixed along the way.

The speed slider gets wired to `StageEngine.setPlaybackSpeed()`
(`lib/engine/stage_engine.dart:367`), but that method has to be implemented
first. An earlier draft of this spec said it already worked and only needed
connecting. It does not. Its body is two comments and nothing else, it ignores
its argument, and `_config` is final, so `_config.playbackSpeed` is read by the
playback tick and is permanently 1.0.

So making the slider work is a small engine change as well as a UI one: hold the
speed in a mutable field, read it in the tick, and restart the playback timer
when it changes mid-play. That is the one place this work reaches below
`lib/ui/`, and it is unavoidable, because wiring a control to a stub would leave
the same dead slider with more code behind it.

Stop and Replay get distinct behaviour, rather than both calling `reset()`.

A denied microphone permission gets a real state with an explanation and a
re-request action instead of failing silently.

## Accessibility

Every colour pair above clears 4.5:1 for text and 3:1 for non-text. Note state
carries shape as well as colour. The focus ring uses the `focus` token, appears
instantly, and is never animated. Reduced motion collapses the notehead tick
while functional motion continues. All transport controls get semantics labels,
which they currently lack, since they are icon-only.

## Testing

Against the CI matrix, this work belongs at unit and widget tests with one
golden. It adds no API route and no new parser, so it does not earn an
integration or end-to-end tier.

Unit tests cover `ProgressRepository` read, write, and upgrade paths, plus the
staff-space geometry math. Widget tests assert that the practice screen renders
without overflow at three landscape sizes, that the HUD title ellipsizes rather
than pushing metrics off-screen, and that the keyboard fits 36 white keys at
each size. One golden per theme covers the practice screen; this is the tier
that would have caught the original overflow.

`pitch_detector_test.dart` must stay green untouched. `staff_painter_test.dart`
will need updating, since the painter is being rewritten, and that is expected
and in scope.

Existing `flutter_lints` and the `custom_lint` plus `riverpod_lint` pair must
pass clean.

## Out of scope

MIDI input, playback of backing audio, and polyphonic detection. A level editor.
Cloud sync or accounts. Scoring both hands independently: the renderer will draw
a grand staff, but per-hand accuracy is engine work and is not part of this
revamp.

## Risks

Bravura adds to bundle size. Subsetting to the glyphs actually used will keep it
small, and the `font-workflow` skill covers the mechanics.

The staff painter rewrite is the largest single piece and carries the most
visual risk. Goldens are the mitigation.

`assets/fonts/` is declared in `pubspec.yaml` but missing on disk. It has to be
created and populated in the same change that references it, or the build
breaks.

The project is now a git repository, but the branch carries the whole rewrite
as a single line of commits. There is limited history to fall back on if
something goes wrong, so each change should stay reviewable as its own diff.
