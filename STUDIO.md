# Studio — generated backgrounds & templates

`lib/studio/` adds a content system on top of the existing editor. Nothing in
the free editor (`StatusPersonalizerScreen`), the hand-authored ready
templates (`fixed_templates.dart`) or the category templates
(`templates_data.dart`) was replaced; the studio *feeds* the same canvases and
the same locked editor (`TemplateFillScreen`) with generated content.

```
shaders/                      GLSL fragment programs (compiled by the Flutter tool)
lib/studio/
  models/                     BackgroundConfig · TemplateConfig · QuoteModel · CategoryModel · LanguageModel
  shaders/                    StudioShaders (program registry) · Layers (typed uniform builders)
  renderers/                  paintBackgroundConfig · GeneratedBackground · BackgroundThumbnails
  background/                 kBackgroundPresets — ~60 recipes, 15 categories
  quotes/                     kStudioQuotes (en + hi) · QuoteRepository
  presets/                    kCategoryPresets (fonts, frames, layouts) · the 8 layout blueprints
  templates/                  TemplateGenerator · TemplateCatalog · BackgroundSwap
  presentation/               template card · language switch · quote & background pickers
```

## Backgrounds are recipes, not images

A `BackgroundConfig` is a base gradient plus an ordered list of layers:

| Layer | Source | Used for |
|---|---|---|
| mesh gradient | `shaders/mesh_gradient.frag` | the opaque base of most designs; soft "blurred" blobs |
| light rays | `shaders/light_rays.frag` | sunrise, diya glow, divine light |
| soft waves | `shaders/soft_waves.frag` | hills, sea, tricolour bands |
| bokeh | `shaders/bokeh.frag` | stars, floating lights, confetti, romance |
| texture overlay | `shaders/texture_overlay.frag` | grain, paper, halftone, dot grid, pinstripes |
| glow / aurora / flowing waves | `flutter_shaders_ui` shaders | moon glow, northern lights, premium flow |
| vignette, shapes | Dart canvas | rings, rules, bands, corner brackets |

Every layer is a **still**: the `flutter_shaders_ui` programs are sampled at
a frozen `uTime`. The config serialises into the design JSON
(`background.generated`), so a saved status reopens pixel-identical on any
device with nothing to download, and the 3× PNG export re-evaluates the
shaders at export resolution instead of upscaling a bitmap.

`paper_shaders` was evaluated and **not** added: every published version
requires Dart ≥ 3.11 / Flutter ≥ 3.41, while this project builds on Dart 3.6 /
Flutter 3.27. Its effects (mesh gradient, grain, paper, dots, waves) are
reproduced by the project-owned shaders above.

## Performance

* Shader programs compile once (`StudioShaders.warmUp()` after the first frame,
  via `flutter_shaders_ui`'s `ShaderCache`) and one `FragmentShader` per
  program is reused — uniforms are rewritten between draws, nothing is
  allocated per paint.
* `GeneratedBackground` is a `CustomPaint` inside `TemplateBackground`'s
  existing `RepaintBoundary`, so typing or dragging never repaints it.
* Grids and pickers use `BackgroundThumb`, an LRU of rasterised tiles
  (`BackgroundThumbnails`, 48 × ~180 KB), so forty tiles cost forty blits,
  not forty shader passes per frame.
* Until a program is ready the painter draws the recipe's gradient, so there
  is never a blank frame — and a GPU that rejects a program degrades to that
  gradient instead of failing.

## Templates

`TemplateCatalog.configsFor(category)` pairs the category's backgrounds with
its layout subset so every (background, layout) combination appears before
any repeats and neighbours never share either. `TemplateGenerator.build`
turns a recipe into a `FixedTemplate` — quotes fetched from
`QuoteRepository` in **both** languages, photo frame from the category
preset, name slot, decorations — which the existing `FixedTemplateCanvas`
renders and `TemplateFillScreen` edits.

Eight layout families (`LayoutType`), each category rotating through its own
subset: large-quote/small-photo, full-image overlay, quote-only, circle
portrait, minimal, photo+signature, traditional, modern premium.

Per-template options (`TemplateCapabilities`) vary on purpose: quote-only,
quote+name, photo+quote, photo+name, everything, background+quote. The
locked editor shows only the tools a design allows (`LockedIdleBar`).

## Additive changes to existing code

* `ImageObject.frameStyle` / `softEdge` and `BackgroundState.generated` —
  new optional fields with JSON defaults; older saved designs load unchanged.
* `PhotoFramePainter` replaces the two identical private border painters in
  the locked canvas and the free editor and adds thin / gold / double / glow
  styles plus a feathered edge (`softenPhotoEdge`).
* `FixedTemplate` gains optional per-language text maps, line allowances,
  quote slot id, alternate backgrounds and a name formatter; every default
  reproduces the previous behaviour for the hand-authored designs.
* `BackgroundSheet` (free editor) gets a "Designer backgrounds" section.
* `CategoryScreen` (opened from the Create tab's Themes grid) lists the
  generated designs for its theme first, then the hand-authored ones, in one
  grid, with an EN / हिं switch for the generated designs' language. Themes
  with only generated content (Success, Friendship, Wishes, Nature,
  Heartbreak, Minimal, Dark) were added to the grid; the mapping is
  `kThemeToStudioCategory`.

## Adding content

* **Background**: add a `BackgroundPreset` to `background_presets.dart`
  (compose with `Layers.*`). It appears in its category's templates and the
  Background sheet automatically.
* **Quote**: add a `QuoteModel` row to `studio_quotes.dart`.
* **Category**: add a `CategoryModel`, a `CategoryPreset` and ≥ 3 backgrounds.
* **Shader**: drop a `.frag` into `shaders/`, list it in `pubspec.yaml`, add a
  constant to `StudioShaders.all` and a typed builder to `Layers`.

Tests: `test/studio_test.dart`.
