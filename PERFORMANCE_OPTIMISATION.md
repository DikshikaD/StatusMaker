# Performance Optimisation Report — status_maker

Scope: safe, high-impact optimisations only. No UI design or feature behaviour was
changed. After applying these, run:

```bash
flutter pub get      # three unused packages were removed
flutter run          # (or hot restart)
```

> Note on verification: this environment has no Dart/Flutter runtime and no
> device, so changes were verified by static review (bracket balance, symbol
> resolution, import checks) — not by launching the app. Please profile on a real
> device with `flutter run --profile` + DevTools to confirm the wins below.

---

## Summary of what changed

| # | Change | File(s) | Priority |
|---|--------|---------|----------|
| 1 | Stop blocking startup on font downloads | `lib/main.dart` | 🔥 Critical |
| 2 | Downscale gallery photos on pick | `status_personalizer_screen.dart` | 🔥 Critical |
| 3 | Decode editor photos at display size (`cacheWidth`) | `editable_image_widget.dart` | 🔥 Critical |
| 4 | `cacheWidth` + fade-in placeholders on all network images | explore / create / preview / community | ⚡ High |
| 5 | `RepaintBoundary` around feed & grid cards | home / category | ⚡ High |
| 6 | Memoise `GoogleFonts` style + isolate preview repaint | `status_card.dart` | ⚡ High |
| 7 | Remove unused packages | `pubspec.yaml` | ✅ Medium |

---

## 1. 🔥 Stop blocking app startup on font downloads

**Why it improves performance:** The old code fetched *every* editor font before
the first frame was allowed to render. `GoogleFonts.getFont` triggers a network
fetch + decode on first use; doing this for the whole font list on the startup
path directly delays time-to-first-frame (a cold-start stall the user feels as
"slow to open"). Moving it to a post-frame callback lets the UI paint
immediately, then warms the font cache in the background.

**Original:**
```dart
await S.init();
for (final f in kEditorFonts) {
  GoogleFonts.getFont(f);          // runs before runApp → blocks first frame
}
runApp(const MyApp());
```

**Optimised:**
```dart
await S.init();
await ThemeController.init();

runApp(const MyApp());             // paint first

WidgetsBinding.instance.addPostFrameCallback((_) {
  for (final f in kEditorFonts) {  // warm cache after UI is visible
    GoogleFonts.getFont(f);
  }
});
```

**Trade-off:** The very first time a template font appears it may load a moment
later. In practice the post-frame warm-up finishes long before the user reaches
the editor, and `google_fonts` caches the result to disk for next launch.

---

## 2. 🔥 Downscale gallery photos on pick

**Why:** `pickImage` was returning full-resolution camera photos (often 12–48 MP).
Every downstream decode of that file allocates enormous bitmaps
(a 12 MP image ≈ 48 MB in memory), causing GC churn, jank, and OOM risk on
low-end devices. A status never needs more than ~1080p, so capping on pick fixes
the problem at the source.

**Original:**
```dart
await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
```

**Optimised:**
```dart
await _picker.pickImage(
  source: ImageSource.gallery,
  imageQuality: 90,
  maxWidth: 1920,
  maxHeight: 1920,
);
```

**Trade-off:** Exported/edited photos are capped at 1920px on the long edge.
This is invisible for social/status sharing (which recompress anyway) and is a
large memory/CPU win.

---

## 3. 🔥 Decode editor photos at display size

**Why:** `Image.file(File(path))` decodes the image at its *full* pixel size
regardless of how small it's shown on the canvas. `cacheWidth` tells the engine
to decode a downscaled bitmap, cutting memory per photo dramatically.

**Original:**
```dart
Image.file(File(image.path), width: size.width, height: size.height,
    fit: BoxFit.cover, gaplessPlayback: true, ...)
```

**Optimised:**
```dart
Image.file(File(image.path), width: size.width, height: size.height,
    fit: BoxFit.cover, gaplessPlayback: true,
    cacheWidth: (size.width * 2).round().clamp(1, 2000), ...)
```

**Trade-off:** If a photo is later scaled up a lot on the canvas it could soften
slightly; the `* 2` factor leaves headroom so this is rarely visible.

---

## 4. ⚡ `cacheWidth` + placeholders on all network images

**Why:** The Unsplash URLs return ~2000px images that were decoded at full size
into small cards, wasting memory and stalling the raster thread on first paint.
Adding `cacheWidth` decodes them near their on-screen size; `loadingBuilder`
shows a neutral placeholder and `frameBuilder` fades the image in, so lists no
longer flash or jank while images resolve.

**Original (representative):**
```dart
Image.network(imageUrl, fit: BoxFit.cover,
  errorBuilder: (_, __, ___) => Icon(Icons.broken_image, ...));
```

**Optimised:**
```dart
Image.network(imageUrl, fit: BoxFit.cover,
  cacheWidth: 500,                       // sized per usage (500/700/900/1080)
  frameBuilder: (c, child, frame, sync) => sync ? child
      : AnimatedOpacity(opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 250), child: child),
  loadingBuilder: (c, child, p) => p == null ? child
      : Container(color: AppColors.cardLight),
  errorBuilder: (_, __, ___) => Icon(Icons.broken_image, ...));
```

Applied in `explore_screen.dart`, `create_screen.dart`,
`status_preview_screen.dart`, `community_submission_screen.dart`.

**Trade-off:** None meaningful. If you later want disk caching across app
restarts, add `cached_network_image` (see "Further recommendations").

---

## 5. ⚡ `RepaintBoundary` around feed & grid cards

**Why:** Each card paints a gradient + a `CustomPaint` motif + styled text.
Without a boundary, one card's press/like animation (or the scroll transform)
can mark a large shared layer dirty, repainting siblings every frame. A
`RepaintBoundary` gives each card its own cached layer, so only the card that
actually changed repaints — the single biggest scroll-smoothness win here.

**Original (home feed):**
```dart
StatusCard(template: templates[i], tag: tag, ...)
```

**Optimised:**
```dart
RepaintBoundary(
  child: StatusCard(template: templates[i], tag: tag, ...),
)
```

Also applied to the `category_screen` grid `itemBuilder`.

**Trade-off:** A small amount of extra layer memory per card — negligible next to
the raster savings.

---

## 6. ⚡ Memoise the font style + isolate the preview repaint (`StatusCard`)

**Why (font):** `GoogleFonts.getFont(...)` was called inside `build()`, so every
like tap and every press-scale frame re-resolved the text style. The template is
immutable, so the style is computed once and cached (invalidated only if the
template swaps in via `didUpdateWidget`).

**Why (repaint):** Wrapping the preview (`gradient + motif + text`) in a
`RepaintBoundary` means toggling "like" repaints only the action bar, not the
expensive preview layer.

**Original:**
```dart
Widget _templateText() {
  final style = GoogleFonts.getFont(_t.fontFamily, ...);   // every rebuild
  final text = Text(_t.text, style: style, ...);
  ...
}
```

**Optimised:**
```dart
TextStyle? _cachedTextStyle;
@override
void didUpdateWidget(covariant StatusCard old) {
  super.didUpdateWidget(old);
  if (old.template != widget.template) _cachedTextStyle = null;
}
TextStyle get _textStyle => _cachedTextStyle ??= GoogleFonts.getFont(_t.fontFamily, ...);

Widget _templateText() {
  final text = Text(_t.text, style: _textStyle, ...);      // reuse cached style
  ...
}
// preview subtree now wrapped in RepaintBoundary(...)
```

**Trade-off:** Slightly more state on the card widget. No behaviour change.

---

## 7. ✅ Remove unused packages

**Why:** `provider`, `shimmer`, and `flutter_colorpicker` were declared in
`pubspec.yaml` but imported in **zero** files. Unused deps bloat the dependency
graph, slow `pub get`/builds, and enlarge the app. State is handled with plain
`ChangeNotifier`/`ValueNotifier` (from Flutter itself), so `provider` isn't
needed.

**Removed:**
```yaml
provider: ^6.1.2
shimmer: ^3.0.0
flutter_colorpicker: ^1.1.0
```

**Trade-off:** If you intended to adopt any of these later, re-add when you
actually use them. Run `flutter pub get` after this change.

---

## What was already good (no change needed)

- **Controller disposal:** every `AnimationController`, `TextEditingController`,
  `FocusNode`, and `PageController` (splash, onboarding, editor canvas) is
  disposed. `EditorController` disposes its `ValueNotifier`s. No leaks found.
- **`EditorController` design:** selection/edit use separate `ValueNotifier`s so
  selecting an object doesn't rebuild the whole canvas — already optimal.
- **`MotifPainter`:** implements `shouldRepaint` correctly and uses no
  unseeded `Random`, so it won't repaint or flicker needlessly.
- **`category_screen`, `create_screen` grids:** already use
  `GridView.builder` / lazy `ListView` with `NeverScrollableScrollPhysics` +
  `shrinkWrap` where nested.

---

## Further recommendations (not applied — need judgement or bigger refactor)

- **✅ Home feed is eager, not lazy.** `home_screen`'s feed builds every
  `StatusCard` at once inside `SingleChildScrollView` + `Column`. For long
  categories this builds many cards up front. Converting to a `CustomScrollView`
  with a `SliverList` would make it lazy — but it's wrapped in an
  `AnimatedSwitcher` (category cross-fade), so doing this safely without changing
  that animation is a larger refactor. Recommended as a follow-up.
- **ℹ️ Disk-persistent network image cache.** Current `Image.network` caches in
  memory only. Add `cached_network_image` if you want images to survive app
  restarts (adds one dependency).
- **ℹ️ `List.unmodifiable` getters in `EditorController`** allocate a new list on
  each access; if the canvas reads them per-frame during drags, cache the list or
  expose the backing list read-only. Minor.
- **ℹ️ Consider `flutter build --analyze-size` and DevTools "Raster"/"Memory"
  tabs** in profile mode to confirm frame times and locate any remaining spikes.
