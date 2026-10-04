import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/template_motif.dart';
import 'package:status_maker/studio/models/background_config.dart';

/// Bump this whenever the JSON shape changes so older saved designs can be
/// migrated on load instead of breaking.
const int kDesignSchemaVersion = 1;

/// Canvas size assumed for a design that doesn't record its own (older rows
/// saved before `canvasSize` existed, and the base fixed templates author
/// against exactly this size — see `kFixedCanvasSize` in fixed_templates.dart,
/// which is defined in terms of this constant).
const Size kDesignDefaultCanvasSize = Size(360, 640);

// ---------------------------------------------------------------------------
// Primitive converters
// ---------------------------------------------------------------------------
// ignore: deprecated_member_use
int _col(Color c) => c.value;
Color _color(dynamic v) => Color((v as num).toInt());

Map<String, double> _off(Offset o) => {'dx': o.dx, 'dy': o.dy};
Offset _offset(dynamic v) {
  final m = v as Map;
  return Offset((m['dx'] as num).toDouble(), (m['dy'] as num).toDouble());
}

double _d(dynamic v, double fallback) => (v as num?)?.toDouble() ?? fallback;

/// Resolve an enum from its `.name`, falling back safely if it's unknown
/// (e.g. an old design referencing a value that was later renamed/removed).
T _enumByName<T>(List<T> values, dynamic name, T fallback) {
  if (name is String) {
    for (final v in values) {
      if ((v as Enum).name == name) return v;
    }
  }
  return fallback;
}

// ---------------------------------------------------------------------------
// Per-object (de)serialization
// ---------------------------------------------------------------------------
Map<String, dynamic> _bgToJson(BackgroundState b) => {
      'color': b.color == null ? null : _col(b.color!),
      'gradient': b.gradientColors?.map(_col).toList(),
      'imagePath': b.imagePath,
      'assetPath': b.assetPath,
      'motif': b.motif.name,
      'motifColor': b.motifColor == null ? null : _col(b.motifColor!),
      // Additive: absent in every design saved before studio backgrounds
      // existed, which deserialize to null and render exactly as before.
      'generated': b.generated?.toJson(),
    };

BackgroundState _bgFromJson(Map j) => BackgroundState(
      color: j['color'] == null ? null : _color(j['color']),
      gradientColors:
          (j['gradient'] as List?)?.map((e) => _color(e)).toList(),
      imagePath: j['imagePath'] as String?,
      assetPath: j['assetPath'] as String?,
      motif: _enumByName(TemplateMotif.values, j['motif'], TemplateMotif.none),
      motifColor: j['motifColor'] == null ? null : _color(j['motifColor']),
      generated: j['generated'] is Map
          ? BackgroundConfig.fromJson(
              Map<String, dynamic>.from(j['generated'] as Map))
          : null,
    );

Map<String, dynamic> _textToJson(TextObject t) => {
      'id': t.id,
      'text': t.text,
      'fontFamily': t.fontFamily,
      'color': _col(t.color),
      'fontSize': t.fontSize,
      'align': t.textAlign.name,
      'bold': t.bold,
      'italic': t.italic,
      'letterSpacing': t.letterSpacing,
      'lineHeight': t.lineHeight,
      'highlight': t.highlight == null ? null : _col(t.highlight!),
      'pos': _off(t.position),
      'scale': t.scale,
      'rotation': t.rotation,
      // Additive: absent in every design saved before hand-resizable text
      // boxes existed. Those deserialize to null, which TextObject resolves to
      // kDefaultTextBoxWidth — the width they were laid out with — so old rows
      // render unchanged and need no migration.
      'boxWidth': t.boxWidth,
      'z': t.zIndex,
    };

TextObject _textFromJson(Map j) => TextObject(
      id: j['id'] as String,
      text: j['text'] as String? ?? '',
      fontFamily: j['fontFamily'] as String? ?? 'Poppins',
      color: _color(j['color']),
      fontSize: _d(j['fontSize'], 30),
      textAlign: _enumByName(TextAlign.values, j['align'], TextAlign.center),
      bold: j['bold'] as bool? ?? true,
      italic: j['italic'] as bool? ?? false,
      letterSpacing: _d(j['letterSpacing'], 0),
      lineHeight: _d(j['lineHeight'], 1.2),
      highlight: j['highlight'] == null ? null : _color(j['highlight']),
      position: _offset(j['pos']),
      scale: _d(j['scale'], 1),
      rotation: _d(j['rotation'], 0),
      boxWidth: (j['boxWidth'] as num?)?.toDouble(),
      zIndex: (j['z'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _imageToJson(ImageObject i) => {
      'id': i.id,
      'path': i.path,
      'shape': i.shape.name,
      'pos': _off(i.position),
      'scale': i.scale,
      'rotation': i.rotation,
      'isPlaceholder': i.isPlaceholder,
      'framed': i.framed,
      'frameColor': _col(i.frameColor),
      // Additive (see ImageObject): older rows lack these and fall back to the
      // crisp classic look they were saved with.
      'frameStyle': i.frameStyle.name,
      'softEdge': i.softEdge,
      'photoOffset': _off(i.photoOffset),
      'photoScale': i.photoScale,
      'z': i.zIndex,
    };

ImageObject _imageFromJson(Map j) => ImageObject(
      id: j['id'] as String,
      path: j['path'] as String? ?? '',
      shape:
          _enumByName(ImageShape.values, j['shape'], ImageShape.roundedRectangle),
      position: _offset(j['pos']),
      scale: _d(j['scale'], 1),
      rotation: _d(j['rotation'], 0),
      isPlaceholder: j['isPlaceholder'] as bool? ?? false,
      framed: j['framed'] as bool? ?? false,
      frameColor:
          j['frameColor'] == null ? Colors.white : _color(j['frameColor']),
      frameStyle: _enumByName(
          PhotoFrameStyle.values, j['frameStyle'], PhotoFrameStyle.classic),
      softEdge: _d(j['softEdge'], 0),
      photoOffset:
          j['photoOffset'] == null ? Offset.zero : _offset(j['photoOffset']),
      photoScale: _d(j['photoScale'], 1),
      zIndex: (j['z'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _elementToJson(ElementObject e) => {
      'id': e.id,
      'shape': e.shape.name,
      'color': _col(e.color),
      'pos': _off(e.position),
      'scale': e.scale,
      'rotation': e.rotation,
      'stroke': e.strokeWidth,
      'assetPath': e.assetPath,
      'z': e.zIndex,
    };

ElementObject _elementFromJson(Map j) => ElementObject(
      id: j['id'] as String,
      shape: _enumByName(ElementShape.values, j['shape'], ElementShape.heart),
      color: _color(j['color']),
      assetPath: j['assetPath'] as String?,
      position: _offset(j['pos']),
      scale: _d(j['scale'], 1),
      rotation: _d(j['rotation'], 0),
      strokeWidth: _d(j['stroke'], 1),
      zIndex: (j['z'] as num?)?.toInt() ?? 0,
    );

// ---------------------------------------------------------------------------
// Content signature
// ---------------------------------------------------------------------------
/// Keys stripped before fingerprinting a design — see
/// [StatusDesign.contentSignature] for why each one is noise.
const Set<String> _signatureIgnoredKeys = {'z', 'canvasW', 'canvasH'};

Object? _normalizeForSignature(Object? v) {
  if (v is Map) {
    return {
      for (final e in v.entries)
        if (!_signatureIgnoredKeys.contains(e.key))
          e.key: _normalizeForSignature(e.value),
    };
  }
  if (v is List) return v.map(_normalizeForSignature).toList();
  if (v is double) {
    final rounded = (v * 10).roundToDouble() / 10;
    // -0.0 and 0.0 are equal but encode differently, which would make an
    // untouched design look edited.
    return rounded == 0 ? 0.0 : rounded;
  }
  return v;
}

// ---------------------------------------------------------------------------
// StatusDesign — the full editable composition, ready for a `jsonb` column.
// ---------------------------------------------------------------------------
class StatusDesign {
  final int schemaVersion;
  final BackgroundState background;
  final List<TextObject> texts;
  final List<ImageObject> images;
  final List<ElementObject> elements;
  final StatusFrame frame;
  final Color frameColor;
  final double frameWidth;

  /// The canvas size (in logical pixels) every position/scale in this design
  /// was authored against. The free editor's canvas isn't a fixed size — it's
  /// however big the device's screen makes it — so without this, reopening a
  /// design on a different device silently reinterprets its coordinates in
  /// the wrong space: text drifts, and elements can land outside the canvas
  /// entirely. See scaleDesignToCanvas() and where it's applied on load in
  /// StatusPersonalizerScreen.
  final Size canvasSize;

  StatusDesign({
    this.schemaVersion = kDesignSchemaVersion,
    required this.background,
    required this.texts,
    required this.images,
    required this.elements,
    this.frame = StatusFrame.none,
    this.frameColor = Colors.white,
    this.frameWidth = 1.0,
    this.canvasSize = kDesignDefaultCanvasSize,
  });

  /// Snapshot the current editor state (used on Save). [canvasSize] must be
  /// the real, laid-out size of the canvas this was edited on, so the design
  /// can be scaled correctly if it's ever reopened on a different device.
  factory StatusDesign.fromController(
    EditorController c, {
    required Size canvasSize,
  }) =>
      StatusDesign(
        background: c.background,
        texts: c.texts,
        images: c.images,
        elements: c.elements,
        frame: c.frame,
        frameColor: c.frameColor,
        frameWidth: c.frameWidth,
        canvasSize: canvasSize,
      );

  Map<String, dynamic> toJson() => {
        'schema': schemaVersion,
        'background': _bgToJson(background),
        'texts': texts.map(_textToJson).toList(),
        'images': images.map(_imageToJson).toList(),
        'elements': elements.map(_elementToJson).toList(),
        'frame': frame.name,
        'frameColor': _col(frameColor),
        'frameWidth': frameWidth,
        'canvasW': canvasSize.width,
        'canvasH': canvasSize.height,
      };

  factory StatusDesign.fromJson(Map<String, dynamic> j) => StatusDesign(
        schemaVersion: (j['schema'] as num?)?.toInt() ?? 1,
        background: _bgFromJson((j['background'] as Map?) ?? const {}),
        texts: ((j['texts'] as List?) ?? const [])
            .map((e) => _textFromJson(e as Map))
            .toList(),
        images: ((j['images'] as List?) ?? const [])
            .map((e) => _imageFromJson(e as Map))
            .toList(),
        elements: ((j['elements'] as List?) ?? const [])
            .map((e) => _elementFromJson(e as Map))
            .toList(),
        frame: _enumByName(StatusFrame.values, j['frame'], StatusFrame.none),
        frameColor:
            j['frameColor'] == null ? Colors.white : _color(j['frameColor']),
        frameWidth: _d(j['frameWidth'], 1),
        // Older rows saved before this existed have no recorded canvas — the
        // safest fallback is the fixed-template size, since that's already
        // the assumption every non-fixed-template save made implicitly before
        // this fix (every canvas the app has ever rendered starts near there).
        canvasSize: j['canvasW'] == null
            ? kDesignDefaultCanvasSize
            : Size(_d(j['canvasW'], kDesignDefaultCanvasSize.width),
                _d(j['canvasH'], kDesignDefaultCanvasSize.height)),
      );

  /// A stable fingerprint of everything a *viewer* of the status would see.
  /// Two designs with the same signature look identical. Used to answer "has
  /// the user actually changed anything?" — see the remix gate in
  /// StatusPersonalizerScreen.
  ///
  /// Deliberately not just `jsonEncode(toJson())`, because three parts of the
  /// JSON move without the design ever looking different:
  ///  * `z` — [EditorController] bumps an object's zIndex when the user merely
  ///    *taps* it (see _bringToFront), and tapping isn't customizing;
  ///  * `canvasW`/`canvasH` — the canvas is however big this device makes it,
  ///    so a design opened on a different-sized phone would never match;
  ///  * raw doubles — a drag that ends a hair from where it started, or the
  ///    float noise from scaleDesignToCanvas, shouldn't read as an edit, so
  ///    every number is rounded to a tenth of a pixel first.
  String get contentSignature => jsonEncode(_normalizeForSignature(toJson()));

  /// Load this design into an editor (used when opening or remixing a status).
  void applyTo(EditorController c) => c.loadDesign(
        background: background,
        texts: texts,
        images: images,
        elements: elements,
        frame: frame,
        frameColor: frameColor,
        frameWidth: frameWidth,
      );
}
