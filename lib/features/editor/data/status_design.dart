import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/template_motif.dart';

/// Bump this whenever the JSON shape changes so older saved designs can be
/// migrated on load instead of breaking.
const int kDesignSchemaVersion = 1;

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
    };

BackgroundState _bgFromJson(Map j) => BackgroundState(
      color: j['color'] == null ? null : _color(j['color']),
      gradientColors:
          (j['gradient'] as List?)?.map((e) => _color(e)).toList(),
      imagePath: j['imagePath'] as String?,
      assetPath: j['assetPath'] as String?,
      motif: _enumByName(TemplateMotif.values, j['motif'], TemplateMotif.none),
      motifColor: j['motifColor'] == null ? null : _color(j['motifColor']),
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
    );

Map<String, dynamic> _elementToJson(ElementObject e) => {
      'id': e.id,
      'shape': e.shape.name,
      'color': _col(e.color),
      'pos': _off(e.position),
      'scale': e.scale,
      'rotation': e.rotation,
      'stroke': e.strokeWidth,
    };

ElementObject _elementFromJson(Map j) => ElementObject(
      id: j['id'] as String,
      shape: _enumByName(ElementShape.values, j['shape'], ElementShape.heart),
      color: _color(j['color']),
      position: _offset(j['pos']),
      scale: _d(j['scale'], 1),
      rotation: _d(j['rotation'], 0),
      strokeWidth: _d(j['stroke'], 1),
    );

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

  StatusDesign({
    this.schemaVersion = kDesignSchemaVersion,
    required this.background,
    required this.texts,
    required this.images,
    required this.elements,
    this.frame = StatusFrame.none,
    this.frameColor = Colors.white,
    this.frameWidth = 1.0,
  });

  /// Snapshot the current editor state (used on Save).
  factory StatusDesign.fromController(EditorController c) => StatusDesign(
        background: c.background,
        texts: c.texts,
        images: c.images,
        elements: c.elements,
        frame: c.frame,
        frameColor: c.frameColor,
        frameWidth: c.frameWidth,
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
      );

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
