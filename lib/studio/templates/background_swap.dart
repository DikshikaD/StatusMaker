import 'package:flutter/material.dart';

import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/studio/models/background_config.dart';

/// Re-colours a locked design's slots when its background is swapped, so a
/// quote designed for a cream card doesn't turn invisible on a midnight one.
///
/// The generator only ever paints text, rules and frames in the palette's
/// three roles (text / muted / accent), so matching on those colours is
/// exact: anything the user recoloured by hand (or the white-on-scrim quote of
/// the full-photo layout) doesn't match and is left alone.
class BackgroundSwap {
  BackgroundSwap._();

  static Color _map(Color c, BackgroundConfig from, BackgroundConfig to) {
    if (c == from.textColor) return to.textColor;
    if (c == from.mutedTextColor) return to.mutedTextColor;
    if (c == from.accentColor) return to.accentColor;
    return c;
  }

  static List<TextObject> texts(
          List<TextObject> texts, BackgroundConfig from, BackgroundConfig to) =>
      [for (final t in texts) t.copyWith(color: _map(t.color, from, to))];

  static List<ElementObject> elements(List<ElementObject> els,
          BackgroundConfig from, BackgroundConfig to) =>
      [for (final e in els) e.copyWith(color: _map(e.color, from, to))];

  static ImageObject? photo(
          ImageObject? img, BackgroundConfig from, BackgroundConfig to) =>
      img?.copyWith(frameColor: _map(img.frameColor, from, to));
}
