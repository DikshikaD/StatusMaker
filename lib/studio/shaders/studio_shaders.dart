import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_shaders_ui/flutter_shaders_ui.dart' show ShaderCache;

import 'package:status_maker/studio/models/background_config.dart';

/// Registry of every fragment program the studio paints with, exposing them
/// *synchronously* to painters.
///
/// `FragmentProgram.fromAsset` is async and compiles on first use, so a
/// painter can't just call it mid-frame. Instead programs are loaded once —
/// through flutter_shaders_ui's [ShaderCache], which de-duplicates concurrent
/// loads and keeps the compiled program for the process lifetime — and a
/// single [ui.FragmentShader] per program is kept here for painters to set
/// uniforms on. [revision] bumps whenever a program finishes loading, so a
/// `CustomPainter` built with `repaint: StudioShaders.revision` repaints
/// exactly once to swap its fallback gradient for the real thing.
///
/// Why one shader instance per program instead of one per paint: creating a
/// `FragmentShader` allocates a native object every time, and the draw calls
/// snapshot uniform values when recorded, so rewriting uniforms between draws
/// is safe and allocation-free.
class StudioShaders {
  StudioShaders._();

  // Project-owned programs (declared under `flutter: shaders:` in pubspec).
  static const String mesh = 'shaders/mesh_gradient.frag';
  static const String rays = 'shaders/light_rays.frag';
  static const String waves = 'shaders/soft_waves.frag';
  static const String bokeh = 'shaders/bokeh.frag';
  static const String texture = 'shaders/texture_overlay.frag';

  // flutter_shaders_ui programs, bundled by that package. Sampled at a frozen
  // time, these give soft glow, aurora bands and flowing waves as stills.
  static const String glowOrb =
      'packages/flutter_shaders_ui/shaders/glow_orb.frag';
  static const String aurora =
      'packages/flutter_shaders_ui/shaders/aurora.frag';
  static const String waveBackground =
      'packages/flutter_shaders_ui/shaders/wave.frag';

  static const List<String> all = [
    mesh,
    rays,
    waves,
    bokeh,
    texture,
    glowOrb,
    aurora,
    waveBackground,
  ];

  /// Increments each time a program becomes available.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static final Map<String, ui.FragmentShader> _shaders = {};
  static final Map<String, Future<void>> _loading = {};
  static final Set<String> _failed = {};

  /// The ready shader for [asset], or null if it hasn't compiled yet (the
  /// load is kicked off so a later frame will have it). Null is also returned
  /// permanently for an asset that failed to load — the background then just
  /// keeps its gradient, which is the whole point of having one.
  static ui.FragmentShader? shaderFor(String asset) {
    final s = _shaders[asset];
    if (s != null) return s;
    if (!_failed.contains(asset)) ensureLoaded(asset);
    return null;
  }

  static bool isLoaded(String asset) => _shaders.containsKey(asset);

  /// Whether every shader [config] needs is ready (or has failed and will be
  /// skipped) — i.e. painting it now gives the final image.
  static bool isReadyFor(BackgroundConfig config) {
    for (final a in config.shaderAssets) {
      if (!_shaders.containsKey(a) && !_failed.contains(a)) return false;
    }
    return true;
  }

  /// Loads [asset] once; concurrent callers share the same future.
  static Future<void> ensureLoaded(String asset) {
    if (_shaders.containsKey(asset) || _failed.contains(asset)) {
      return Future.value();
    }
    return _loading.putIfAbsent(asset, () async {
      try {
        final program = await ShaderCache.load(asset);
        _shaders[asset] = program.fragmentShader();
        revision.value++;
      } catch (e) {
        // A device whose GPU driver rejects a program (or an asset missing
        // from a build) must not take the editor down — the base gradient
        // carries the design instead.
        _failed.add(asset);
        debugPrint('StudioShaders: failed to load $asset — $e');
      } finally {
        _loading.remove(asset);
      }
    });
  }

  /// Loads everything [config] paints with.
  static Future<void> ensureFor(BackgroundConfig config) =>
      Future.wait(config.shaderAssets.toSet().map(ensureLoaded));

  /// Compiles every program in the background. Call after the first frame
  /// (alongside the font warm-up in main.dart) so the first generated
  /// background the user sees is already the finished picture, not the
  /// fallback gradient.
  static Future<void> warmUp() => Future.wait(all.map(ensureLoaded));
}
