# Performance Optimisation Report — status_maker

Scope: safe, high-impact optimisations only. No UI design or feature behaviour was
changed. After applying these, run:

> **Update (pass 2 — editor jank):** the app was reported as "very slow and
> unresponsive" after the fixes below had already landed. The remaining
> bottleneck was entirely inside the *editor* (`StatusPersonalizerScreen` /
> `StatusCanvas`), which the first pass hadn't covered. See
> "Pass 2 — Editor responsiveness" further down for the actual fixes.

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

---

## Pass 2 — Editor responsiveness (the actual "slow and unresponsive" fix)

> Same caveat as above: no Dart/Flutter runtime or device is available in this
> environment, so these were verified by static review + manual bracket/type
> checking, not by running `flutter run --profile`. Please confirm with
> DevTools' "Performance"/"Raster" tabs, especially while dragging the
> size/letter-spacing/line-height sliders in the editor with 3-4 text objects
> on the canvas.

The editor screen (`StatusPersonalizerScreen` → `StatusCanvas`) wraps the whole
canvas in a single `AnimatedBuilder(animation: _controller, ...)`. That means
**any** controller change — adding/removing an object, picking a background,
or dragging a style slider (which calls `notifyListeners()` on every drag
frame, so dozens of times per second) — rebuilds every object on the canvas,
not just the one being edited. Three things made that rebuild expensive:

| # | Change | File(s) | Priority |
|---|--------|---------|----------|
| 1 | Memoise resolved `GoogleFonts` text styles | `text_style_builder.dart` | 🔥 Critical |
| 2 | Give each canvas object its own repaint layer | `transformable_object.dart` | 🔥 Critical |
| 3 | Cache the controller's `images`/`texts`/`elements` views | `editor_controller.dart` | ⚡ High |

### 1. 🔥 Memoise `buildTextStyle`

**Why:** `buildTextStyle()` called `GoogleFonts.getFont()` fresh on every
build — and every text object's `EditableTextWidget` rebuilds on every canvas
rebuild (see above), so with N text objects on the canvas, a single slider
drag re-resolved N Google Fonts styles per frame, even for the N-1 objects
whose style hadn't changed at all that frame. This is the same anti-pattern
that was already fixed in `StatusCard` (pass 1, item 6) — it just hadn't been
applied to the editor itself, which is where users actually spend their time.

**Original:**
```dart
TextStyle buildTextStyle(TextObject t) {
  final base = TextStyle(...);
  return GoogleFonts.getFont(t.fontFamily, textStyle: base);
}
```

**Optimised:** a small capped cache keyed on the style-relevant fields, so
identical style combinations resolve instantly instead of re-walking Google
Fonts' font table and re-merging the `TextStyle` every call.
```dart
final Map<String, TextStyle> _styleCache = {};
const int _styleCacheCap = 200;

TextStyle buildTextStyle(TextObject t) {
  final key = '${t.fontFamily}|${t.color}|${t.fontSize}|${t.bold}|'
      '${t.italic}|${t.letterSpacing}|${t.lineHeight}';
  final cached = _styleCache[key];
  if (cached != null) return cached;
  final style = GoogleFonts.getFont(t.fontFamily, textStyle: TextStyle(...));
  if (_styleCache.length >= _styleCacheCap) {
    _styleCache.remove(_styleCache.keys.first);
  }
  _styleCache[key] = style;
  return style;
}
```

**Trade-off:** the cache is capped at 200 entries (oldest evicted first) so a
slider drag — which mints a new key every frame for the object actually being
resized — can't grow it unbounded. Output is byte-for-byte identical; nothing
about the rendered style changes.

### 2. 🔥 Per-object `RepaintBoundary` in `TransformableObject`

**Why:** the entire canvas (background + every image/text/element + frame)
sits under **one** `RepaintBoundary` (used to rasterise the export). Without a
boundary per object, dragging/pinching/rotating any single object marks that
shared layer dirty, so the whole canvas repaints every frame of the
gesture — every other photo, text and sticker included — even though nothing
about them changed.

**Original:**
```dart
return Positioned(
  left: _position.dx,
  top: _position.dy,
  child: Transform.rotate(...),
);
```

**Optimised:**
```dart
return Positioned(
  left: _position.dx,
  top: _position.dy,
  child: RepaintBoundary(
    child: Transform.rotate(...),
  ),
);
```

Now dragging one object repaints only its own layer. This is the direct
editor-canvas equivalent of pass 1's fix #5 (RepaintBoundary around feed
cards) and is very likely the single biggest contributor to the "unresponsive"
feel, since dragging is the most frequent, most frame-rate-sensitive
interaction in the editor.

**Trade-off:** one extra compositing layer per on-canvas object — negligible
next to the raster savings, same as pass 1's card boundaries.

### 3. ⚡ Cache `EditorController`'s list views

**Why:** `images`/`texts`/`elements` getters returned `List.unmodifiable(_x)`,
which copies the backing list on *every* access. `StatusCanvas.build()` reads
all three every rebuild — so every drag-frame notification allocated three
fresh lists regardless of whether that particular list changed.

**Original:**
```dart
List<ImageObject> get images => List.unmodifiable(_images);
```

**Optimised:** cache the view, invalidate only at the mutation sites that
actually touch that list.
```dart
List<ImageObject>? _imagesView;
List<ImageObject> get images => _imagesView ??= List.unmodifiable(_images);
// each mutator (addImage, updateImageTransform, deleteImage, ...) sets
// _imagesView = null right before notifyListeners().
```

**Trade-off:** none — same immutable-view contract for callers, just cached
until the next mutation of that specific list.

---

## Further recommendations (not applied — need judgement or bigger refactor)

- **✅ Home feed laziness** — already resolved: `home_screen` now builds its
  feed with `SliverList.separated` inside a `CustomScrollView`, so only visible
  cards are built.
- **✅ `List.unmodifiable` getters in `EditorController`** — resolved in Pass 2
  (item 3 above).
- **ℹ️ Disk-persistent network image cache.** Current `Image.network` caches in
  memory only. Add `cached_network_image` if you want images to survive app
  restarts (adds one dependency).
- **ℹ️ The editor's single canvas-wide `AnimatedBuilder`.** `StatusCanvas` is
  still rebuilt in full on every controller change (see Pass 2 intro) — Pass 2
  made that rebuild cheap (memoised styles, isolated repaint layers, cached
  list views) rather than eliminating it. A deeper fix would give each object
  its own `ListenableBuilder`/`Selector`-style scoped listener so unrelated
  objects don't even re-run `build()`. Not attempted here since it touches the
  controller's rebuild architecture more invasively than a pure perf pass
  should — worth doing only if profiling still shows the canvas rebuild itself
  (not paint) as a bottleneck after this pass.
- **ℹ️ Consider `flutter build --analyze-size` and DevTools "Raster"/"Memory"
  tabs** in profile mode to confirm frame times and locate any remaining spikes.
