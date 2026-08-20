# Piano-Tool UI revamp, Plan 1: visual foundation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the token layer, theme, bundled fonts, and a rewritten staff renderer, so the app has a tested visual foundation the five-screen shell can sit on.

**Architecture:** Everything below `lib/ui/` is untouched. New code lands in `lib/ui/theme/` (tokens and theme) and `lib/ui/staff/` (geometry and painter). The staff is sized entirely in staff-spaces derived from the widget's height, so one code path serves both a single staff and a grand staff. All verification runs on `ampere-dev`; the Mac stays source-only.

**Tech Stack:** Flutter (stable), Dart, `flutter_test` with golden files, bundled OTF/TTF fonts (Cormorant Garamond, IBM Plex Sans, Bravura).

**Spec:** `docs/specs/2026-08-17-ui-revamp-design.md`

## Global constraints

- No build artifacts on the Mac. `pub get`, `analyze`, and `test` run on `ampere-dev` only.
- No `Card` elevation and no shadows anywhere. Depth comes from weight and lightness.
- Every colour and text style is referenced through a token name. No inline `Color(0x...)` or `TextStyle(fontFamily: ...)` outside `lib/ui/theme/`.
- No Inter. Display is Cormorant Garamond roman, never italic. Body is IBM Plex Sans.
- Accent (`accent`, ink blue) is limited to the playhead, the due note, and the primary action.
- Note state carries shape as well as colour. Never colour alone.
- Text contrast at least 4.5:1, non-text at least 3:1.
- Flutter SDK on the VM lives at `~/flutter/bin`.

### Verified baseline, measured after Task 1

Measured on branch `ui-revamp-foundation` at commit `d23240b`:

- `flutter test`: 8 tests, **7 pass and 1 fails**. The failure is
  `test/widget_test.dart`, "PianoToolApp smoke test builds successfully",
  which is pre-existing. All three test files are discovered.
- `flutter analyze`: **83 issues, all `info` severity.** `flutter analyze`
  exits nonzero on infos, which is why every verification step in this plan
  runs `flutter test` first and passes `--no-fatal-infos` to analyze.

No task may increase either number. Reducing them is not this plan's job,
with one exception: Task 4 rewrites `PianoToolApp`, so it owns fixing
`widget_test.dart` and must leave the suite fully green.

---

### Task 1: Flutter toolchain on the VM, and Flutter support in verify-on-vm

Setup task. No app code changes. Its deliverable is a working `verify-on-vm <path> "flutter test"` round trip.

**Files:**
- Modify: `/Users/yinkavaughan/bin/verify-on-vm` (local, outside the repo)

**Interfaces:**
- Consumes: nothing.
- Produces: the command `verify-on-vm "<repo path>" "flutter test"`, used by every later task.

- [ ] **Step 1: Confirm the Flutter install finished on the VM**

```bash
ssh ampere-dev 'export PATH="$HOME/flutter/bin:$PATH"; flutter --version && dart --version'
```

Expected: a Flutter version line and a Dart version line, both reporting `linux_arm64`.

- [ ] **Step 2: Add Flutter cache exclusions to verify-on-vm**

In `/Users/yinkavaughan/bin/verify-on-vm`, the `rsync` call at line 33 deletes anything on the VM not present locally. `.dart_tool/` is a VM-side cache and must survive. Add these three excludes to the existing list:

```bash
  --exclude .dart_tool --exclude .flutter-plugins-dependencies --exclude .flutter-plugins \
```

- [ ] **Step 3: Put Flutter on the remote PATH**

Change the `export PATH=` line (line 45) to include the Flutter bin directory:

```bash
export PATH="$HOME/flutter/bin:$HOME/.cargo/bin:$HOME/go/bin:/usr/local/go/bin:$HOME/.bun/bin:$HOME/.foundry/bin:$HOME/.local/bin:$PATH"
```

- [ ] **Step 4: Teach check_deps about pubspec.lock**

Inside `check_deps()`, after the `Gemfile.lock` line, add:

```bash
  run_check "$dir" "pubspec.lock" "flutter pub get" "pub"
```

- [ ] **Step 5: Add Flutter to build autodetection**

In the `if [ -z "$BUILD_CMD" ]` block, add a branch before the final `else`:

```bash
  elif [ -f pubspec.yaml ]; then
    BUILD_CMD="flutter test"
```

- [ ] **Step 6: Verify the round trip against the current repo**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test && flutter analyze --no-fatal-infos"
```

Expected: `flutter pub get` runs once, then `analyze` and the three existing tests run. `pitch_detector_test.dart` and `staff_painter_test.dart` should pass. If `staff_painter_test.dart` fails, record the failure but do not fix it; Task 6 rewrites that painter.

- [ ] **Step 7: Verify the cache survives a second run**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test"
```

Expected: `--- dependencies up to date in './pubspec.lock', skipping install ---`. If it reinstalls, Step 2 did not take effect.

- [ ] **Step 8: Record the Android SDK finding**

```bash
ssh ampere-dev 'export PATH="$HOME/flutter/bin:$PATH"; flutter doctor -v 2>&1 | head -30'
```

Android toolchain will report missing. Do not install it yet. Append one line to the plan's Task 8 notes stating whether `flutter doctor` reports any arm64-specific problem, since Google ships no Linux ARM64 build-tools. Nothing in Tasks 2 through 7 needs Android; they are all pure Dart and widget tests.

- [ ] **Step 9: Commit**

`verify-on-vm` lives outside the repo, so there is nothing to commit here. Confirm the repo is still clean:

```bash
cd "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" && git status --short
```

Expected: no output.

---

### Task 2: Design tokens

**Files:**
- Create: `lib/ui/theme/tokens.dart`
- Test: `test/ui/theme/tokens_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `PianoColors` with named `Color` fields and a `const PianoColors.light()` / `const PianoColors.dark()` pair; `PianoSpacing` constants; `argbLight` and `argbDark` maps of `String` to `int` for testing.

- [ ] **Step 1: Write the failing test**

Create `test/ui/theme/tokens_test.dart`:

```dart
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/theme/tokens.dart';

double _channel(int argb, int shift) => ((argb >> shift) & 0xFF) / 255.0;

double _linear(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(int argb) =>
    0.2126 * _linear(_channel(argb, 16)) +
    0.7152 * _linear(_channel(argb, 8)) +
    0.0722 * _linear(_channel(argb, 0));

double _contrast(int a, int b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final entry in {'light': argbLight, 'dark': argbDark}.entries) {
    final name = entry.key;
    final t = entry.value;

    test('$name: text tokens clear 4.5:1 on paper', () {
      for (final key in ['ink', 'ink2', 'muted', 'accent', 'success', 'error']) {
        expect(_contrast(t[key]!, t['paper']!), greaterThanOrEqualTo(4.5),
            reason: '$name.$key on paper');
      }
    });

    test('$name: staff lines clear 3:1 on paper', () {
      expect(_contrast(t['staff']!, t['paper']!), greaterThanOrEqualTo(3.0));
    });

    test('$name: accentInk is readable on accent', () {
      expect(_contrast(t['accentInk']!, t['accent']!), greaterThanOrEqualTo(4.5));
    });

    test('$name: every token is fully opaque', () {
      for (final e in t.entries) {
        expect((e.value >> 24) & 0xFF, 0xFF, reason: '${e.key} must be opaque');
      }
    });
  }

  test('light and dark define the same token names', () {
    expect(argbLight.keys.toSet(), argbDark.keys.toSet());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test test/ui/theme/tokens_test.dart"
```

Expected: FAIL, `Target of URI doesn't exist: 'package:piano_tool/ui/theme/tokens.dart'`.

- [ ] **Step 3: Write the implementation**

Create `lib/ui/theme/tokens.dart`. The ARGB maps are the single source of truth; `PianoColors` reads from them so the two can never drift.

```dart
import 'package:flutter/widgets.dart';

/// Colour tokens, authored in OKLCH and converted to sRGB.
/// The OKLCH source is kept alongside each value so the palette stays
/// auditable. Hue never changes between themes; only lightness and chroma.
const Map<String, int> argbLight = {
  'paper': 0xFFFFFFFF,     // oklch(100%  0     0)
  'paper2': 0xFFF9F6F2,    // oklch(97.5% 0.006 72)
  'paper3': 0xFFF1ECE6,    // oklch(94.5% 0.010 72)
  'ink': 0xFF1A1510,       // oklch(20%   0.012 68)
  'ink2': 0xFF47413C,      // oklch(38%   0.012 68)
  'staff': 0xFF807971,     // oklch(58%   0.014 72)
  'rule': 0xFFC9C3BC,      // oklch(82%   0.012 72)
  'rule2': 0xFFE2DDD7,     // oklch(90%   0.010 72)
  'muted': 0xFF68625C,     // oklch(50%   0.012 68)
  'accent': 0xFF2757B6,    // oklch(48%   0.16  262)
  'accentInk': 0xFFFDFBF9, // oklch(99%   0.004 72)
  'focus': 0xFF1F5ED9,     // oklch(52%   0.20  262)
  'success': 0xFF067132,   // oklch(48%   0.13  150)
  'error': 0xFFB63132,     // oklch(52%   0.17  25)
};

const Map<String, int> argbDark = {
  'paper': 0xFF110C07,     // oklch(16% 0.014 72)
  'paper2': 0xFF1B150E,    // oklch(20% 0.016 72)
  'paper3': 0xFF241E17,    // oklch(24% 0.016 72)
  'ink': 0xFFECE7E1,       // oklch(93% 0.010 72)
  'ink2': 0xFFAFAAA4,      // oklch(74% 0.010 72)
  'staff': 0xFF7A736C,     // oklch(56% 0.014 72)
  'rule': 0xFF4D4740,      // oklch(40% 0.014 72)
  'rule2': 0xFF322D27,     // oklch(30% 0.012 72)
  'muted': 0xFF8B857F,     // oklch(62% 0.012 68)
  'accent': 0xFF6591E1,    // oklch(66% 0.13  262)
  'accentInk': 0xFF15110C, // oklch(18% 0.012 68)
  'focus': 0xFF68A1FF,     // oklch(72% 0.17  262)
  'success': 0xFF5DAD70,   // oklch(68% 0.12  150)
  'error': 0xFFD8625C,     // oklch(64% 0.15  25)
};

@immutable
class PianoColors {
  const PianoColors._(this._argb);

  factory PianoColors.light() => const PianoColors._(argbLight);
  factory PianoColors.dark() => const PianoColors._(argbDark);

  final Map<String, int> _argb;

  Color _c(String name) => Color(_argb[name]!);

  Color get paper => _c('paper');
  Color get paper2 => _c('paper2');
  Color get paper3 => _c('paper3');
  Color get ink => _c('ink');
  Color get ink2 => _c('ink2');
  Color get staff => _c('staff');
  Color get rule => _c('rule');
  Color get rule2 => _c('rule2');
  Color get muted => _c('muted');
  Color get accent => _c('accent');
  Color get accentInk => _c('accentInk');
  Color get focus => _c('focus');
  Color get success => _c('success');
  Color get error => _c('error');
}

/// 4pt spacing scale, named by role.
abstract final class PianoSpacing {
  static const double xs2 = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 40;
  static const double xl2 = 64;
  static const double xl3 = 96;
}

/// Motion. One moment only: the notehead tick on hit.
abstract final class PianoMotion {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 220);
  static const Curve easeOut = Cubic(0.16, 1, 0.3, 1);
  static const Curve easeIn = Cubic(0.7, 0, 0.84, 0);
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test test/ui/theme/tokens_test.dart"
```

Expected: PASS, 9 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/theme/tokens.dart test/ui/theme/tokens_test.dart
git commit -m "Add colour, spacing, and motion tokens

Tokens are authored in OKLCH and stored as sRGB ARGB integers, with the
OKLCH source in comments so the palette stays auditable. The test asserts
every text token clears 4.5:1 against paper and staff lines clear 3:1, in
both themes."
```

---

### Task 3: Bundle the three fonts

The spec assumed `google_fonts` would serve Cormorant and Plex. Runtime fetching makes golden tests hit the network and gives the app a first-launch flicker with no offline guarantee, so all three faces get bundled and the dependency is dropped.

**Files:**
- Create: `assets/fonts/` with six font files
- Modify: `pubspec.yaml`
- Test: `test/ui/theme/fonts_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: font families `CormorantGaramond`, `IBMPlexSans`, and `Bravura`, resolvable by name in any `TextStyle`.

- [ ] **Step 1: Download the fonts**

All three are SIL OFL 1.1 and free to redistribute.

```bash
cd "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool"
mkdir -p assets/fonts
BASE=https://raw.githubusercontent.com/google/fonts/main
curl -fL -o assets/fonts/CormorantGaramond-SemiBold.ttf "$BASE/ofl/cormorantgaramond/CormorantGaramond-SemiBold.ttf"
curl -fL -o assets/fonts/CormorantGaramond-Bold.ttf     "$BASE/ofl/cormorantgaramond/CormorantGaramond-Bold.ttf"
curl -fL -o assets/fonts/IBMPlexSans-Regular.ttf        "$BASE/ofl/ibmplexsans/IBMPlexSans-Regular.ttf"
curl -fL -o assets/fonts/IBMPlexSans-Medium.ttf         "$BASE/ofl/ibmplexsans/IBMPlexSans-Medium.ttf"
curl -fL -o assets/fonts/IBMPlexSans-SemiBold.ttf       "$BASE/ofl/ibmplexsans/IBMPlexSans-SemiBold.ttf"
curl -fL -o assets/fonts/Bravura.otf "https://raw.githubusercontent.com/steinbergmedia/bravura/master/redist/otf/Bravura.otf"
ls -la assets/fonts/
```

Expected: six files, none zero bytes. If a Cormorant path 404s, list the directory with
`curl -s https://api.github.com/repos/google/fonts/contents/ofl/cormorantgaramond | grep '"name"'`
and use the exact filenames returned. Do not substitute a different family.

- [ ] **Step 2: Write the failing test**

Create `test/ui/theme/fonts_test.dart`:

```dart
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const expected = [
    'assets/fonts/CormorantGaramond-SemiBold.ttf',
    'assets/fonts/CormorantGaramond-Bold.ttf',
    'assets/fonts/IBMPlexSans-Regular.ttf',
    'assets/fonts/IBMPlexSans-Medium.ttf',
    'assets/fonts/IBMPlexSans-SemiBold.ttf',
    'assets/fonts/Bravura.otf',
  ];

  for (final path in expected) {
    test('$path is bundled and non-empty', () async {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(1000));
    });
  }

  test('Bravura contains the treble and bass clef glyphs', () async {
    final data = await rootBundle.load('assets/fonts/Bravura.otf');
    final loader = ui.FontLoader('Bravura')..addFont(Future.value(data));
    await loader.load();

    // U+E050 gClef, U+E062 fClef in the SMuFL private-use range.
    for (final code in [0xE050, 0xE062]) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Bravura'))
        ..addText(String.fromCharCode(code));
      final paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 200));
      expect(paragraph.maxIntrinsicWidth, greaterThan(0),
          reason: 'glyph U+${code.toRadixString(16).toUpperCase()} missing');
    }
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test test/ui/theme/fonts_test.dart"
```

Expected: FAIL, `Unable to load asset`, because `pubspec.yaml` does not declare the fonts yet.

- [ ] **Step 4: Declare the fonts and drop google_fonts**

In `pubspec.yaml`, delete the `google_fonts: ^6.1.0` line from `dependencies`, and replace the `flutter:` block's asset section with:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/levels/
  fonts:
    - family: CormorantGaramond
      fonts:
        - asset: assets/fonts/CormorantGaramond-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/CormorantGaramond-Bold.ttf
          weight: 700
    - family: IBMPlexSans
      fonts:
        - asset: assets/fonts/IBMPlexSans-Regular.ttf
          weight: 400
        - asset: assets/fonts/IBMPlexSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/IBMPlexSans-SemiBold.ttf
          weight: 600
    - family: Bravura
      fonts:
        - asset: assets/fonts/Bravura.otf
```

The bare `- assets/fonts/` directory entry is removed. Declaring fonts under `fonts:` is what registers the families; listing the directory under `assets:` only ships the bytes. This also resolves the missing-directory problem noted in the spec.

- [ ] **Step 5: Run test to verify it passes**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter pub get && flutter test test/ui/theme/fonts_test.dart"
```

Expected: PASS, 7 tests.

- [ ] **Step 6: Confirm nothing still imports google_fonts**

```bash
rg -n 'google_fonts|GoogleFonts' lib/ test/
```

Expected: two hits in `lib/main.dart` only. Leave them; Task 4 replaces that file's theme.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/fonts test/ui/theme/fonts_test.dart
git commit -m "Bundle Cormorant Garamond, IBM Plex Sans, and Bravura

Runtime font fetching made golden tests depend on the network and gave the
app a first-launch flicker with no offline guarantee. Bundling all three
faces removes the google_fonts dependency and fills the assets/fonts entry
that pubspec declared but never had on disk.

Bravura is the SMuFL reference font, needed because the Unicode clef
codepoints render from whatever the OS supplies and are missing entirely on
some Android builds."
```

---

### Task 4: Theme

**Files:**
- Create: `lib/ui/theme/app_theme.dart`
- Modify: `lib/main.dart:1-41`
- Test: `test/ui/theme/app_theme_test.dart`

**Interfaces:**
- Consumes: `PianoColors`, `PianoSpacing` from Task 2; the font families from Task 3.
- Produces: `PianoTheme.light()` and `PianoTheme.dark()` returning `ThemeData`; `PianoTheme.colorsOf(BuildContext)` returning `PianoColors`; a `PianoColors` `ThemeExtension` so widgets read tokens by name.

- [ ] **Step 1: Write the failing test**

Create `test/ui/theme/app_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';
import 'package:piano_tool/ui/theme/tokens.dart';

void main() {
  testWidgets('light theme exposes tokens and uses the bundled faces',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      theme: PianoTheme.light(),
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));

    final colors = PianoTheme.colorsOf(ctx);
    expect(colors.paper, PianoColors.light().paper);
    expect(colors.accent, PianoColors.light().accent);

    final theme = Theme.of(ctx);
    expect(theme.scaffoldBackgroundColor, PianoColors.light().paper);
    expect(theme.textTheme.bodyMedium!.fontFamily, 'IBMPlexSans');
    expect(theme.textTheme.headlineSmall!.fontFamily, 'CormorantGaramond');
  });

  testWidgets('dark theme swaps tokens but keeps the same families',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      theme: PianoTheme.dark(),
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));

    expect(PianoTheme.colorsOf(ctx).paper, PianoColors.dark().paper);
    expect(Theme.of(ctx).textTheme.bodyMedium!.fontFamily, 'IBMPlexSans');
  });

  testWidgets('no display text style is italic', (tester) async {
    final theme = PianoTheme.light();
    for (final style in [
      theme.textTheme.displayLarge,
      theme.textTheme.headlineLarge,
      theme.textTheme.headlineSmall,
      theme.textTheme.titleLarge,
    ]) {
      expect(style!.fontStyle ?? FontStyle.normal, FontStyle.normal);
    }
  });

  testWidgets('metric style uses tabular figures', (tester) async {
    expect(
      PianoTheme.light().textTheme.labelLarge!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test test/ui/theme/app_theme_test.dart"
```

Expected: FAIL, `Target of URI doesn't exist: '.../app_theme.dart'`.

- [ ] **Step 3: Write the implementation**

Create `lib/ui/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'tokens.dart';

/// Makes the token set reachable from any BuildContext.
@immutable
class PianoColorsExtension extends ThemeExtension<PianoColorsExtension> {
  const PianoColorsExtension(this.colors);

  final PianoColors colors;

  @override
  PianoColorsExtension copyWith({PianoColors? colors}) =>
      PianoColorsExtension(colors ?? this.colors);

  @override
  PianoColorsExtension lerp(ThemeExtension<PianoColorsExtension>? other, double t) =>
      t < 0.5 ? this : (other as PianoColorsExtension? ?? this);
}

abstract final class PianoTheme {
  static ThemeData light() => _build(PianoColors.light(), Brightness.light);
  static ThemeData dark() => _build(PianoColors.dark(), Brightness.dark);

  static PianoColors colorsOf(BuildContext context) =>
      Theme.of(context).extension<PianoColorsExtension>()!.colors;

  static ThemeData _build(PianoColors c, Brightness brightness) {
    // Display is Cormorant, roman only. Body and every metric is Plex Sans.
    //
    // Both faces are variable fonts registered with no weight entries in
    // pubspec, so `fontWeight` alone would not move the axis — it would let
    // the engine synthesise a fake bold. `fontVariations` drives the real
    // 'wght' axis; `fontWeight` stays alongside it so weight-aware widgets
    // and any fallback face still behave.
    TextStyle display(double size, int weight, double height) => TextStyle(
          fontFamily: 'CormorantGaramond',
          fontWeight: FontWeight.values.firstWhere((w) => w.value == weight),
          fontVariations: [FontVariation('wght', weight.toDouble())],
          fontSize: size, height: height, color: c.ink,
        );

    TextStyle body(double size, int weight, double height, Color color,
            {bool tabular = false}) =>
        TextStyle(
          fontFamily: 'IBMPlexSans',
          fontWeight: FontWeight.values.firstWhere((w) => w.value == weight),
          fontVariations: [FontVariation('wght', weight.toDouble())],
          fontSize: size, height: height, color: color,
          fontFeatures:
              tabular ? const [FontFeature.tabularFigures()] : null,
        );

    final text = TextTheme(
      displayLarge: display(44, 700, 1.08),
      headlineLarge: display(32, 700, 1.12),
      headlineSmall: display(22, 600, 1.15),
      titleLarge: display(20, 600, 1.2),
      bodyLarge: body(16, 400, 1.55, c.ink),
      bodyMedium: body(14, 400, 1.5, c.ink2),
      bodySmall: body(12, 400, 1.45, c.muted),
      // labelLarge is the metric role: anything numeric that changes.
      labelLarge: body(13, 600, 1.2, c.ink, tabular: true),
      labelSmall: body(11, 500, 1.2, c.muted, tabular: true),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.paper,
      canvasColor: c.paper,
      dividerColor: c.rule,
      textTheme: text,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.accent,
        onPrimary: c.accentInk,
        secondary: c.accent,
        onSecondary: c.accentInk,
        error: c.error,
        onError: c.paper,
        surface: c.paper,
        onSurface: c.ink,
        surfaceContainerHighest: c.paper3,
        outline: c.rule,
      ),
      // Depth is weight and lightness, never shadow.
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      appBarTheme: AppBarTheme(
          elevation: 0, scrolledUnderElevation: 0,
          backgroundColor: c.paper2, foregroundColor: c.ink),
      dividerTheme: DividerThemeData(color: c.rule, thickness: 1, space: 1),
      extensions: [PianoColorsExtension(c)],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test test/ui/theme/app_theme_test.dart"
```

Expected: PASS, 4 tests.

- [ ] **Step 5: Wire the theme into main.dart and lock orientation**

Replace the whole of `lib/main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/theme/app_theme.dart';
import 'ui/game/game_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The whole app is landscape. Locking a single screen would rotate the
  // user in and out as they navigate.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ProviderScope(child: PianoToolApp()));
}

class PianoToolApp extends ConsumerWidget {
  const PianoToolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Piano Tool',
      debugShowCheckedModeBanner: false,
      theme: PianoTheme.light(),
      darkTheme: PianoTheme.dark(),
      themeMode: ThemeMode.system,
      home: const GameScreen(),
    );
  }
}
```

`GameScreen` stays as the home for now. Plan 2 replaces it with the router.

- [ ] **Step 6: Fix the pre-existing widget test**

`test/widget_test.dart` currently fails, because it pumps `PianoToolApp`,
which reaches `GameScreen` and its audio engine. This task rewrites
`PianoToolApp`, so this task owns the test. Replace its body with one that
asserts the theme wiring rather than booting the whole app:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';
import 'package:piano_tool/ui/theme/tokens.dart';

void main() {
  testWidgets('app applies the Piano-Tool theme', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      theme: PianoTheme.light(),
      darkTheme: PianoTheme.dark(),
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold(body: SizedBox());
      }),
    ));
    expect(Theme.of(ctx).scaffoldBackgroundColor, PianoColors.light().paper);
    expect(PianoTheme.colorsOf(ctx).accent, PianoColors.light().accent);
  });
}
```

Booting the real `PianoToolApp` in a unit test would require a microphone and
an asset bundle; that belongs in an integration test, which this plan does not
add.

- [ ] **Step 7: Run the whole suite**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test && flutter analyze --no-fatal-infos"
```

Expected: all tests pass, zero failures. This is the first task that must
leave the suite fully green. `google_fonts` is gone from `main.dart`, so
nothing imports it. Analyze must report no more than the 83 baseline infos.

- [ ] **Step 8: Commit**

```bash
git add lib/ui/theme/app_theme.dart test/widget_test.dart lib/main.dart test/ui/theme/app_theme_test.dart
git commit -m "Add themed Material 3 substrate and lock to landscape

Tokens reach widgets through a ThemeExtension, so nothing outside the theme
directory names a colour directly. Card and AppBar elevation are zeroed
because a Material shadow becomes a glow on the dark ground.

Replaces the default blue ColorScheme.fromSeed and the Inter text theme."
```

---

### Task 5: Staff geometry

Pure Dart, no widgets. This is the module that makes a grand staff free.

**Files:**
- Create: `lib/ui/staff/staff_geometry.dart`
- Test: `test/ui/staff/staff_geometry_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `enum Clef { treble, bass }`; `StaffGeometry` with `const StaffGeometry({required double top, required double height})`; getters `space`, `lineY(int index)`, `topLineY`, `bottomLineY`; methods `yForMidi(int midi, Clef clef)`, `ledgerLinesFor(int midi, Clef clef)`, `noteheadSize`, `stemLength`, `timeSignatureFontSize`, `clefFontSize(Clef)`, `clefCenterY(Clef)`.

**Correction to the spec.** The spec says a level "declares one `clef`". That is
wrong: `lib/models/level_models.dart` has no clef type at all. `LevelModel`
carries `clefOctave` (an int) and `transpose`, and the current painter hardcodes
a treble clef. The README documents a level format that does not match the
models either.

`Clef` is therefore defined here, in the UI layer, as the rendering concept it
is. `StaffView` takes an explicit list of systems and each names its own clef,
so the caller decides what to draw. Adding a `clef` field to `LevelModel`
belongs to Plan 2, where the level format and the screen that reads it are both
in scope. This keeps Plan 1's "models untouched" constraint honest and blocks
nothing.

- [ ] **Step 1: Write the failing test**

Create `test/ui/staff/staff_geometry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/ui/staff/staff_geometry.dart';

void main() {
  // A staff 80px tall starting at y=10: 4 spaces of 20px each.
  const g = StaffGeometry(top: 10, height: 80);

  test('one space is a quarter of the staff height', () {
    expect(g.space, 20);
  });

  test('lines run top to bottom at even spacing', () {
    expect(g.lineY(0), 10);   // top line
    expect(g.lineY(4), 90);   // bottom line
    expect(g.topLineY, 10);
    expect(g.bottomLineY, 90);
  });

  group('treble clef', () {
    test('E4 sits on the bottom line', () {
      expect(g.yForMidi(64, Clef.treble), 90);
    });
    test('F5 sits on the top line', () {
      expect(g.yForMidi(77, Clef.treble), 10);
    });
    test('C4 sits one ledger line below the staff', () {
      // C4 is 2 diatonic steps below E4, so one full space below the bottom line.
      expect(g.yForMidi(60, Clef.treble), 110);
      expect(g.ledgerLinesFor(60, Clef.treble), [110.0]);
    });
    test('a note inside the staff needs no ledger lines', () {
      expect(g.ledgerLinesFor(71, Clef.treble), isEmpty);
    });
    test('accidentals share a line with their natural', () {
      // F#5 and F5 occupy the same staff position.
      expect(g.yForMidi(78, Clef.treble), g.yForMidi(77, Clef.treble));
    });
  });

  group('bass clef', () {
    test('G2 sits on the bottom line', () {
      expect(g.yForMidi(43, Clef.bass), 90);
    });
    test('A3 sits on the top line', () {
      expect(g.yForMidi(57, Clef.bass), 10);
    });
    test('C4 sits one ledger line above the staff', () {
      // C4 is 10 diatonic steps above G2, one full space above the top line.
      expect(g.yForMidi(60, Clef.bass), -10);
      expect(g.ledgerLinesFor(60, Clef.bass), [-10.0]);
    });
  });

  test('glyph sizes are expressed in staff spaces', () {
    expect(g.noteheadSize.height, g.space);
    expect(g.noteheadSize.width, closeTo(g.space * 1.3, 0.001));
    expect(g.stemLength, g.space * 3.5);
    expect(g.timeSignatureFontSize, g.space * 2);
  });

  test('halving the staff halves every derived measurement', () {
    const half = StaffGeometry(top: 0, height: 40);
    expect(half.space, g.space / 2);
    expect(half.noteheadSize.height, g.noteheadSize.height / 2);
    expect(half.clefFontSize(Clef.treble), g.clefFontSize(Clef.treble) / 2);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test test/ui/staff/staff_geometry_test.dart"
```

Expected: FAIL, `Target of URI doesn't exist: '.../staff_geometry.dart'`.

- [ ] **Step 3: Confirm no Clef type already exists**

```bash
rg -n 'enum Clef|class Clef' lib/ --glob '!*.freezed.dart' --glob '!*.g.dart'
```

Expected: no matches. `Clef` is introduced by this task. If a match appears, stop and report it rather than defining a second one.

- [ ] **Step 4: Write the implementation**

Create `lib/ui/staff/staff_geometry.dart`:

```dart
import 'dart:ui' show Size;
import 'package:flutter/foundation.dart' show immutable;

/// Which clef a staff is drawn in.
///
/// This is a rendering concept and lives in the UI layer. The level models
/// carry no clef today; `StaffView` takes an explicit list of systems and each
/// one names its clef, so the caller decides what gets drawn.
enum Clef { treble, bass }

/// Staff measurements derived from the staff's own height.
///
/// Every glyph is expressed in staff-spaces rather than as a fraction of the
/// widget, which is what lets a grand staff reuse this untouched: halve the
/// height and everything scales with it.
@immutable
class StaffGeometry {
  const StaffGeometry({required this.top, required this.height});

  /// y of the top staff line.
  final double top;

  /// Distance from the top line to the bottom line.
  final double height;

  /// Four spaces between five lines.
  double get space => height / 4;

  double lineY(int index) => top + index * space;
  double get topLineY => lineY(0);
  double get bottomLineY => lineY(4);

  Size get noteheadSize => Size(space * 1.3, space);
  double get stemLength => space * 3.5;
  double get timeSignatureFontSize => space * 2;

  /// Bravura draws clefs on a staff of 4 spaces at font-size = 4 spaces.
  double clefFontSize(Clef clef) => space * 4;

  /// Bravura anchors gClef to the G line and fClef to the F line.
  double clefCenterY(Clef clef) =>
      switch (clef) { Clef.treble => lineY(3), Clef.bass => lineY(1) };

  /// Diatonic index of the note on the staff's bottom line.
  static const int _trebleBottom = 30; // E4
  static const int _bassBottom = 18;   // G2

  /// Maps a chromatic pitch class to its diatonic degree, so a sharp shares a
  /// staff position with its natural.
  static const List<int> _degree = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6];

  static int _diatonic(int midi) {
    final octave = (midi ~/ 12) - 1;
    return octave * 7 + _degree[midi % 12];
  }

  int _bottomFor(Clef clef) =>
      switch (clef) { Clef.treble => _trebleBottom, Clef.bass => _bassBottom };

  /// Each diatonic step moves half a space.
  double yForMidi(int midi, Clef clef) =>
      bottomLineY - (_diatonic(midi) - _bottomFor(clef)) * (space / 2);

  /// Ledger lines between the staff and a note that sits outside it.
  List<double> ledgerLinesFor(int midi, Clef clef) {
    final steps = _diatonic(midi) - _bottomFor(clef);
    final lines = <double>[];
    if (steps < 0) {
      for (var s = -2; s >= steps; s -= 2) {
        lines.add(bottomLineY - s * (space / 2));
      }
    } else if (steps > 8) {
      for (var s = 10; s <= steps; s += 2) {
        lines.add(bottomLineY - s * (space / 2));
      }
    }
    return lines;
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test test/ui/staff/staff_geometry_test.dart"
```

Expected: PASS, 12 tests.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/staff/staff_geometry.dart test/ui/staff/staff_geometry_test.dart
git commit -m "Add staff geometry in staff-space units

Note positions come from diatonic index rather than MIDI number, so a sharp
shares a staff position with its natural instead of landing half a space
away. Sizing everything from the staff height is what makes a grand staff
free: halve the band and every glyph follows."
```

---

### Task 6: Notehead and staff painter

**Files:**
- Create: `lib/ui/staff/note_glyph.dart`
- Rewrite: `lib/ui/staff/staff_painter.dart` (currently 375 lines)
- Test: `test/ui/staff/note_glyph_test.dart`
- Rewrite: `test/staff_painter_test.dart`

**Interfaces:**
- Consumes: `StaffGeometry` and `Clef` from Task 5; `PianoColors` from Task 2; `NoteState` from `lib/models/engine_models.dart`.

**Correction to the spec.** `NoteState` has SIX values, not four:
`upcoming, active, hitPerfect, hitGood, hitOkay, missed`. There is no
`NoteState.hit`. The spec's four-row table describes four *visual* states, so
the three hit gradations all map to the same filled glyph. Encoding hit quality
visually is a scoring-feedback decision the spec never made, and inventing one
here would be scope creep; it is noted for Plan 2.
- Produces: `NoteGlyph.paint(Canvas, Offset, StaffGeometry, NoteState, PianoColors, {bool stemDown})`; `NoteGlyphStyle.forState(NoteState, PianoColors)` returning a record `({Color color, bool filled, bool ringed, bool struck})`.

- [ ] **Step 1: Write the failing test for glyph style**

Create `test/ui/staff/note_glyph_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/ui/staff/note_glyph.dart';
import 'package:piano_tool/ui/theme/tokens.dart';

void main() {
  final c = PianoColors.light();

  String sig(NoteState s) {
    final st = NoteGlyphStyle.forState(s, c);
    return '${st.filled}-${st.ringed}-${st.struck}';
  }

  const hits = [NoteState.hitPerfect, NoteState.hitGood, NoteState.hitOkay];

  test('six states collapse to four distinct shapes', () {
    expect(NoteState.values.map(sig).toSet().length, 4);
  });

  test('upcoming, active, hit, and missed are all shape-distinct', () {
    final four = {
      sig(NoteState.upcoming),
      sig(NoteState.active),
      sig(NoteState.hitPerfect),
      sig(NoteState.missed),
    };
    expect(four.length, 4);
  });

  test('all three hit gradations render identically', () {
    expect(hits.map(sig).toSet().length, 1);
  });

  test('hit is filled and missed is hollow', () {
    for (final h in hits) {
      expect(NoteGlyphStyle.forState(h, c).filled, isTrue);
    }
    expect(NoteGlyphStyle.forState(NoteState.missed, c).filled, isFalse);
  });

  test('missed carries a strike, hit does not', () {
    expect(NoteGlyphStyle.forState(NoteState.missed, c).struck, isTrue);
    for (final h in hits) {
      expect(NoteGlyphStyle.forState(h, c).struck, isFalse);
    }
  });

  test('states map to their token colours', () {
    for (final h in hits) {
      expect(NoteGlyphStyle.forState(h, c).color, c.success);
    }
    expect(NoteGlyphStyle.forState(NoteState.missed, c).color, c.error);
    expect(NoteGlyphStyle.forState(NoteState.upcoming, c).color, c.muted);
    expect(NoteGlyphStyle.forState(NoteState.active, c).color, c.accent);
  });
}
```

- [ ] **Step 2: Confirm the NoteState enum**

```bash
rg -n 'enum NoteState' -A 8 lib/models/engine_models.dart
```

Expected exactly: `upcoming, active, hitPerfect, hitGood, hitOkay, missed`. If it differs, stop and report rather than guessing a mapping.

- [ ] **Step 3: Run test to verify it fails**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test test/ui/staff/note_glyph_test.dart"
```

Expected: FAIL, `Target of URI doesn't exist: '.../note_glyph.dart'`.

- [ ] **Step 4: Write the glyph implementation**

Create `lib/ui/staff/note_glyph.dart`:

```dart
import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import '../../models/engine_models.dart';
import '../theme/tokens.dart';
import 'staff_geometry.dart';

typedef GlyphStyle = ({Color color, bool filled, bool ringed, bool struck});

/// Note state is a shape first and a colour second.
///
/// Encoding state only as green against red is invisible to red-green colour
/// blindness. Filled against hollow noteheads is real notation, so carrying
/// the distinction in shape costs nothing.
abstract final class NoteGlyphStyle {
  static GlyphStyle forState(NoteState state, PianoColors c) =>
      switch (state) {
        // All three hit gradations share one glyph. Encoding hit quality
        // visually is a scoring-feedback decision this plan does not make.
        NoteState.hitPerfect ||
        NoteState.hitGood ||
        NoteState.hitOkay =>
          (color: c.success, filled: true, ringed: false, struck: false),
        NoteState.missed => (color: c.error, filled: false, ringed: false, struck: true),
        NoteState.active => (color: c.accent, filled: true, ringed: true, struck: false),
        NoteState.upcoming => (color: c.muted, filled: false, ringed: false, struck: false),
      };
}

abstract final class NoteGlyph {
  /// Noteheads are tilted the way engraved heads are.
  static const double _tilt = -0.35; // radians, about -20 degrees

  static void paint(
    Canvas canvas,
    Offset center,
    StaffGeometry g,
    NoteState state,
    PianoColors colors, {
    bool stemDown = true,
  }) {
    final style = NoteGlyphStyle.forState(state, colors);
    final size = g.noteheadSize;
    final stroke = g.space * 0.18;

    if (style.ringed) {
      canvas.drawCircle(
        center,
        size.width * 0.72,
        Paint()..color = style.color.withValues(alpha: 0.22),
      );
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_tilt);
    final rect = Rect.fromCenter(
        center: Offset.zero, width: size.width, height: size.height);
    canvas.drawOval(
      rect,
      Paint()
        ..color = style.color
        ..style = style.filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.restore();

    // Stems are drawn in staff space, not inside the rotated head, so they
    // stay vertical instead of inheriting the tilt.
    final stemX = center.dx + (stemDown ? -size.width / 2 : size.width / 2);
    final stemY = center.dy + (stemDown ? g.stemLength : -g.stemLength);
    canvas.drawLine(
      Offset(stemX, center.dy),
      Offset(stemX, stemY),
      Paint()
        ..color = style.color
        ..strokeWidth = g.space * 0.12,
    );

    if (style.struck) {
      final r = size.width * 0.85;
      final dx = r * math.cos(-0.6);
      final dy = r * math.sin(-0.6);
      canvas.drawLine(
        Offset(center.dx - dx, center.dy - dy),
        Offset(center.dx + dx, center.dy + dy),
        Paint()
          ..color = style.color
          ..strokeWidth = g.space * 0.16
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test test/ui/staff/note_glyph_test.dart"
```

Expected: PASS, 4 tests. If `withValues` is unavailable on this Flutter version, use `withOpacity(0.22)`.

- [ ] **Step 6: Rewrite the staff painter**

Replace `lib/ui/staff/staff_painter.dart` entirely. It draws one system: staff lines, clef, time signature, barlines, ledger lines, noteheads, and the playhead. Grand staff is two instances, not a special case.

```dart
import 'package:flutter/rendering.dart';
import '../../models/engine_models.dart';
import '../theme/tokens.dart';
import 'note_glyph.dart';
import 'staff_geometry.dart';

/// A note positioned in beats, resolved to a MIDI number.
typedef PlacedNote = ({int midi, double startBeat, NoteState state});

class StaffPainter extends CustomPainter {
  StaffPainter({
    required this.clef,
    required this.notes,
    required this.colors,
    required this.currentBeat,
    required this.totalBeats,
    required this.beatsPerMeasure,
    required this.pixelsPerBeat,
    required this.leadingBeats,
  });

  final Clef clef;
  final List<PlacedNote> notes;
  final PianoColors colors;
  final double currentBeat;
  final double totalBeats;
  final int beatsPerMeasure;
  final double pixelsPerBeat;

  /// Horizontal room reserved for the clef and time signature.
  final double leadingBeats;

  @override
  void paint(Canvas canvas, Size size) {
    // The staff occupies the middle 56% of the band, leaving room above and
    // below for ledger lines.
    final staffHeight = size.height * 0.56;
    final g = StaffGeometry(top: (size.height - staffHeight) / 2, height: staffHeight);

    final linePaint = Paint()
      ..color = colors.staff
      ..strokeWidth = 1.0;

    for (var i = 0; i < 5; i++) {
      final y = g.lineY(i);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final barPaint = Paint()
      ..color = colors.staff.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;
    for (var beat = beatsPerMeasure; beat <= totalBeats; beat += beatsPerMeasure) {
      final x = _xForBeat(beat.toDouble());
      canvas.drawLine(Offset(x, g.topLineY), Offset(x, g.bottomLineY), barPaint);
    }

    _paintGlyph(canvas, _clefCodepoint(clef), g.clefFontSize(clef),
        Offset(g.space * 0.5, g.clefCenterY(clef)), colors.ink);

    _paintTimeSignature(canvas, g);

    for (final note in notes) {
      final x = _xForBeat(note.startBeat);
      final y = g.yForMidi(note.midi, clef);

      for (final ledgerY in g.ledgerLinesFor(note.midi, clef)) {
        canvas.drawLine(
          Offset(x - g.space, ledgerY),
          Offset(x + g.space, ledgerY),
          linePaint,
        );
      }

      // Notes above the middle line hang their stems down.
      NoteGlyph.paint(canvas, Offset(x, y), g, note.state, colors,
          stemDown: y < g.lineY(2));
    }

    final playheadX = _xForBeat(currentBeat);
    final playheadPaint = Paint()
      ..color = colors.accent
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(playheadX, 0), Offset(playheadX, size.height), playheadPaint);
    canvas.drawCircle(Offset(playheadX, 0), 3.5, Paint()..color = colors.accent);
  }

  double _xForBeat(double beat) => (beat + leadingBeats) * pixelsPerBeat;

  static int _clefCodepoint(Clef clef) =>
      switch (clef) { Clef.treble => 0xE050, Clef.bass => 0xE062 };

  void _paintGlyph(
      Canvas canvas, int codepoint, double fontSize, Offset anchor, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(codepoint),
        style: TextStyle(fontFamily: 'Bravura', fontSize: fontSize, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // Bravura's glyph origin sits on its reference staff line, so the anchor
    // is the baseline rather than the visual centre.
    painter.paint(canvas, Offset(anchor.dx, anchor.dy - painter.computeDistanceToActualBaseline(TextBaseline.alphabetic)));
  }

  void _paintTimeSignature(Canvas canvas, StaffGeometry g) {
    final x = g.space * 5.5;
    final style = TextStyle(
      fontFamily: 'CormorantGaramond',
      fontWeight: FontWeight.w700,
      fontSize: g.timeSignatureFontSize,
      height: 0.88,
      color: colors.ink,
    );
    for (final (i, digit) in ['$beatsPerMeasure', '4'].indexed) {
      final painter = TextPainter(
        text: TextSpan(text: digit, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x, g.lineY(i == 0 ? 0 : 2)));
    }
  }

  @override
  bool shouldRepaint(StaffPainter old) =>
      old.currentBeat != currentBeat ||
      old.notes != notes ||
      old.colors != colors ||
      old.clef != clef;
}
```

- [ ] **Step 7: Replace the old painter test**

Delete `test/staff_painter_test.dart` and create `test/ui/staff/staff_painter_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/ui/staff/staff_geometry.dart';
import 'package:piano_tool/ui/staff/staff_painter.dart';
import 'package:piano_tool/ui/theme/tokens.dart';

StaffPainter _painter({Clef clef = Clef.treble, double beat = 0}) => StaffPainter(
      clef: clef,
      notes: const [
        (midi: 60, startBeat: 0, state: NoteState.hitPerfect),
        (midi: 64, startBeat: 1, state: NoteState.missed),
        (midi: 67, startBeat: 2, state: NoteState.active),
        (midi: 72, startBeat: 3, state: NoteState.upcoming),
      ],
      colors: PianoColors.light(),
      currentBeat: beat,
      totalBeats: 8,
      beatsPerMeasure: 4,
      pixelsPerBeat: 60,
      leadingBeats: 2,
    );

void main() {
  test('painting does not throw for either clef', () {
    for (final clef in Clef.values) {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      _painter(clef: clef).paint(canvas, const Size(600, 200));
      expect(recorder.endRecording(), isNotNull);
    }
  });

  test('repaints when the playhead moves, not otherwise', () {
    expect(_painter(beat: 1).shouldRepaint(_painter(beat: 0)), isTrue);
    expect(_painter(beat: 0).shouldRepaint(_painter(beat: 0)), isFalse);
  });
}
```

- [ ] **Step 8: Run the full suite**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test && flutter analyze --no-fatal-infos"
```

Expected: PASS. `horizontal_staff.dart` and `game_screen.dart` still reference the old painter's constructor and will fail to analyze. Update their call sites minimally to the new signature; do not redesign them, since Plan 2 replaces both.

- [ ] **Step 9: Commit**

```bash
git add -A lib/ui/staff test/ui/staff
git rm -f test/staff_painter_test.dart 2>/dev/null || true
git commit -m "Rewrite the staff painter on staff-space geometry

Draws one system: lines, clef, time signature, barlines, ledger lines,
noteheads, playhead. A grand staff is two instances rather than a special
case.

Clefs now come from bundled Bravura instead of Unicode codepoints, which
rendered from whatever font the OS supplied and were missing on some Android
builds. Note state carries shape as well as colour, so hit and missed are
distinguishable without seeing red or green."
```

---

### Task 7: Staff widget and goldens

**Files:**
- Create: `lib/ui/staff/staff_view.dart`
- Test: `test/ui/staff/staff_view_test.dart`
- Create: `test/ui/staff/goldens/` (generated)

**Interfaces:**
- Consumes: everything from Tasks 2 through 6.
- Produces: `StaffView({required List<StaffSystem> systems, required double currentBeat, ...})`; `StaffSystem` record `({Clef clef, List<PlacedNote> notes})`.

- [ ] **Step 1: Write the failing test**

Create `test/ui/staff/staff_view_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_tool/models/engine_models.dart';
import 'package:piano_tool/ui/staff/staff_geometry.dart';
import 'package:piano_tool/ui/staff/staff_painter.dart';
import 'package:piano_tool/ui/staff/staff_view.dart';
import 'package:piano_tool/ui/theme/app_theme.dart';

const _treble = (clef: Clef.treble, notes: <PlacedNote>[
  (midi: 60, startBeat: 0, state: NoteState.hitPerfect),
  (midi: 64, startBeat: 1, state: NoteState.missed),
  (midi: 67, startBeat: 2, state: NoteState.active),
  (midi: 72, startBeat: 3, state: NoteState.upcoming),
]);
const _bass = (clef: Clef.bass, notes: <PlacedNote>[
  (midi: 48, startBeat: 0, state: NoteState.hitGood),
  (midi: 55, startBeat: 2, state: NoteState.upcoming),
]);

Widget _harness(ThemeData theme, List<StaffSystem> systems) => MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SizedBox(
          width: 740,
          height: 220,
          child: StaffView(
            systems: systems,
            currentBeat: 2,
            totalBeats: 8,
            beatsPerMeasure: 4,
            pixelsPerBeat: 70,
          ),
        ),
      ),
    );

void main() {
  testWidgets('renders a single staff without overflow', (tester) async {
    await tester.pumpWidget(_harness(PianoTheme.light(), const [_treble]));
    expect(tester.takeException(), isNull);
    expect(find.byType(StaffView), findsOneWidget);
  });

  testWidgets('renders a grand staff without overflow', (tester) async {
    await tester.pumpWidget(_harness(PianoTheme.light(), const [_treble, _bass]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('golden: single staff, light', (tester) async {
    await tester.pumpWidget(_harness(PianoTheme.light(), const [_treble]));
    await expectLater(find.byType(StaffView),
        matchesGoldenFile('goldens/staff_single_light.png'));
  });

  testWidgets('golden: single staff, dark', (tester) async {
    await tester.pumpWidget(_harness(PianoTheme.dark(), const [_treble]));
    await expectLater(find.byType(StaffView),
        matchesGoldenFile('goldens/staff_single_dark.png'));
  });

  testWidgets('golden: grand staff, light', (tester) async {
    await tester.pumpWidget(_harness(PianoTheme.light(), const [_treble, _bass]));
    await expectLater(find.byType(StaffView),
        matchesGoldenFile('goldens/staff_grand_light.png'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test test/ui/staff/staff_view_test.dart"
```

Expected: FAIL, `Target of URI doesn't exist: '.../staff_view.dart'`.

- [ ] **Step 3: Write the implementation**

Create `lib/ui/staff/staff_view.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'staff_geometry.dart';
import 'staff_painter.dart';

typedef StaffSystem = ({Clef clef, List<PlacedNote> notes});

/// Draws one system per entry, splitting the available height between them.
/// A grand staff is two systems; nothing about the painter changes.
class StaffView extends StatelessWidget {
  const StaffView({
    super.key,
    required this.systems,
    required this.currentBeat,
    required this.totalBeats,
    required this.beatsPerMeasure,
    required this.pixelsPerBeat,
    this.leadingBeats = 2,
  });

  final List<StaffSystem> systems;
  final double currentBeat;
  final double totalBeats;
  final int beatsPerMeasure;
  final double pixelsPerBeat;
  final double leadingBeats;

  @override
  Widget build(BuildContext context) {
    final colors = PianoTheme.colorsOf(context);
    return ColoredBox(
      color: colors.paper,
      child: Column(
        children: [
          for (final system in systems)
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: StaffPainter(
                  clef: system.clef,
                  notes: system.notes,
                  colors: colors,
                  currentBeat: currentBeat,
                  totalBeats: totalBeats,
                  beatsPerMeasure: beatsPerMeasure,
                  pixelsPerBeat: pixelsPerBeat,
                  leadingBeats: leadingBeats,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Generate the goldens**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test --update-goldens test/ui/staff/staff_view_test.dart"
```

Then copy the generated images back, since the VM holds them:

```bash
rsync -a ampere-dev:work/verify/piano-tool/test/ui/staff/goldens/ \
  "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool/test/ui/staff/goldens/"
```

- [ ] **Step 5: Inspect the goldens before trusting them**

Open the three PNGs and check against `docs/specs/2026-08-17-ui-revamp-design.md`: five staff lines clearly visible, clef spanning the staff, four visually distinct note states, stems vertical, playhead at beat 2. A golden that captures a wrong rendering is worse than no golden.

- [ ] **Step 6: Run the test against the committed goldens**

```bash
verify-on-vm "/Users/yinkavaughan/My Drive (yvaughan@wesleyan.edu)/CS/projects/personal/piano-tool" "flutter test && flutter analyze --no-fatal-infos"
```

Expected: PASS, whole suite, goldens matching.

- [ ] **Step 7: Commit**

```bash
git add lib/ui/staff/staff_view.dart test/ui/staff/staff_view_test.dart test/ui/staff/goldens
git commit -m "Add StaffView with goldens for single and grand staff

One system per entry, splitting the available height, so a grand staff needs
no separate rendering path. Goldens cover both themes and are the tier that
would have caught the original layout overflow."
```

---

## Task 8: Android SDK viability (notes)

Deferred. Google ships no Linux ARM64 Android build-tools, so `aapt2` on `ampere-dev` is expected to be an x86_64 binary that cannot execute. Nothing in Tasks 1 through 7 needs it; all tests are pure Dart and widget tests that run headless.

Record the `flutter doctor -v` output from Task 1 Step 8 here, then decide between an `android.aapt2FromMavenOverride`, running build-tools under `box64`, or building the APK somewhere else. This blocks on-device runs only, not the plan.

---

## Self-review

**Spec coverage.** Tokens (Task 2), type and the Inter removal (Tasks 3 and 4), Bravura and the `assets/fonts/` fix (Task 3), spacing and motion tokens (Task 2), no-elevation rule (Task 4), landscape lock (Task 4), note state as shape (Task 6), staff-space sizing and data-driven single-or-grand staff (Tasks 5 through 7), goldens per theme (Task 7). Not covered here, and deferred to Plan 2: the five screens, routing, the Riverpod wrapping of `StageEngine`, `ProgressRepository`, the practice-screen layout with its 60dp control column, the keyboard rewrite, the microphone-permission state, the speed slider wiring, and Stop versus Replay. Those all depend on this foundation.

**Placeholders.** None. Every step carries the command or the code. Three steps deliberately verify an assumption against the codebase before implementing (Task 5 Step 3, Task 6 Step 2, and the `withValues` fallback in Task 6 Step 5) rather than guessing at enum names or an API that varies by Flutter version.

**Type consistency.** `PlacedNote` is defined in `staff_painter.dart` (Task 6) and consumed by `staff_view.dart` and both test files. `StaffSystem` is defined in `staff_view.dart` (Task 7). `PianoColors` is defined in `tokens.dart` (Task 2) and reached through `PianoTheme.colorsOf` (Task 4). `StaffGeometry.clefFontSize` and `clefCenterY` both take a `Clef` and are used in `staff_painter.dart`. `NoteGlyphStyle.forState` returns the `GlyphStyle` record used in `note_glyph_test.dart`.
