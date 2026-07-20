import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/data/template_motif.dart';

/// The five shapes a floating image can take. Nothing else.
enum ImageShape { square, roundedRectangle, circle, oval, heart }

/// A floating image placed on the canvas. Multiple are allowed.
class ImageObject {
  final String id;
  String path; // local gallery file path ('' when it's an empty placeholder)
  ImageShape shape;
  Offset position; // top-left of the base box, in canvas coordinates
  double scale;
  double rotation; // radians
  bool isPlaceholder; // true = a shaped "add photo" frame, not yet filled
  bool framed; // draw a decorative border around the photo's shape
  Color frameColor;

  ImageObject({
    required this.id,
    required this.path,
    this.shape = ImageShape.roundedRectangle,
    this.position = const Offset(70, 180),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.isPlaceholder = false,
    this.framed = false,
    this.frameColor = Colors.white,
  });

  ImageObject copyWith({
    String? path,
    ImageShape? shape,
    Offset? position,
    double? scale,
    double? rotation,
    bool? isPlaceholder,
    bool? framed,
    Color? frameColor,
  }) {
    return ImageObject(
      id: id,
      path: path ?? this.path,
      shape: shape ?? this.shape,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
      framed: framed ?? this.framed,
      frameColor: frameColor ?? this.frameColor,
    );
  }
}

/// A text object. Multiple are allowed. Carries the full (and only) set of
/// styling controls the spec calls for.
class TextObject {
  final String id;
  String text;
  String fontFamily;
  Color color;
  double fontSize;
  TextAlign textAlign;
  bool bold;
  bool italic;
  double letterSpacing;
  double lineHeight;
  Color? highlight; // optional bar/pill behind the text
  Offset position;
  double scale;
  double rotation; // radians

  TextObject({
    required this.id,
    this.text = '',
    this.fontFamily = 'Poppins',
    this.color = Colors.white,
    this.fontSize = 30.0,
    this.textAlign = TextAlign.center,
    this.bold = true,
    this.italic = false,
    this.letterSpacing = 0.0,
    this.lineHeight = 1.2,
    this.highlight,
    this.position = const Offset(60, 220),
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  TextObject copyWith({
    String? text,
    String? fontFamily,
    Color? color,
    double? fontSize,
    TextAlign? textAlign,
    bool? bold,
    bool? italic,
    double? letterSpacing,
    double? lineHeight,
    Color? highlight,
    Offset? position,
    double? scale,
    double? rotation,
  }) {
    return TextObject(
      id: id,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      textAlign: textAlign ?? this.textAlign,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      highlight: highlight ?? this.highlight,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}

/// Decorative vector elements (stickers) the user can drop on the canvas.
/// All are drawn in code by [ElementPainter] — no image assets needed.
enum ElementShape {
  heart,
  star,
  circle,
  ring,
  sparkle,
  flower,
  diamond,
  triangle,
  line,
  arrow,
}

/// A single vector element placed on the canvas. Multiple are allowed.
class ElementObject {
  final String id;
  ElementShape shape;
  Color color;
  Offset position;
  double scale;
  double rotation; // radians
  double strokeWidth; // thickness multiplier for stroked shapes (ring/line/arrow)

  ElementObject({
    required this.id,
    required this.shape,
    this.color = Colors.white,
    this.position = const Offset(120, 240),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.strokeWidth = 1.0,
  });

  ElementObject copyWith({
    ElementShape? shape,
    Color? color,
    Offset? position,
    double? scale,
    double? rotation,
    double? strokeWidth,
  }) {
    return ElementObject(
      id: id,
      shape: shape ?? this.shape,
      color: color ?? this.color,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

/// Full-status decorative borders drawn around the whole canvas by
/// [FramePainter]. Only one is active at a time.
enum StatusFrame {
  none,
  thin,
  thick,
  doubleLine,
  dashed,
  rounded,
  corners,
  inset,
}

/// The background can be a solid colour, a gradient (both "built-in"), or a
/// picked gallery image. Only one is active at a time.
class BackgroundState {
  final Color? color;
  final List<Color>? gradientColors;
  final String? imagePath; // gallery file path
  final String? assetPath; // bundled asset image (e.g. category background)
  final TemplateMotif motif; // decorative overlay (part of the design)
  final Color? motifColor;

  const BackgroundState({
    this.color,
    this.gradientColors,
    this.imagePath,
    this.assetPath,
    this.motif = TemplateMotif.none,
    this.motifColor,
  });

  bool get isGradient => gradientColors != null && gradientColors!.isNotEmpty;
  bool get isImage => imagePath != null;
  bool get isAsset => assetPath != null;
}

class EditorController extends ChangeNotifier {
  int _seq = 0;
  String _generateId() => '${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  BackgroundState _background = const BackgroundState(color: Color(0xFF0F172A));
  BackgroundState get background => _background;

  final List<ImageObject> _images = [];
  List<ImageObject> get images => List.unmodifiable(_images);

  final List<TextObject> _texts = [];
  List<TextObject> get texts => List.unmodifiable(_texts);

  final List<ElementObject> _elements = [];
  List<ElementObject> get elements => List.unmodifiable(_elements);

  StatusFrame _frame = StatusFrame.none;
  StatusFrame get frame => _frame;

  Color _frameColor = Colors.white;
  Color get frameColor => _frameColor;

  double _frameWidth = 1.0; // thickness multiplier for the full-status frame
  double get frameWidth => _frameWidth;

  /// Fires with a text id when a text should immediately enter inline editing
  /// (e.g. right after the user taps "Text"). The canvas listens and opens the
  /// keyboard, then resets this to null.
  final ValueNotifier<String?> editRequest = ValueNotifier<String?>(null);

  /// Kept separate from [notifyListeners] so selecting/deselecting only rebuilds
  /// selection frames + the contextual toolbar — never the whole canvas.
  final ValueNotifier<String?> selectedId = ValueNotifier<String?>(null);

  TextObject? get selectedText {
    final id = selectedId.value;
    if (id == null) return null;
    for (final t in _texts) {
      if (t.id == id) return t;
    }
    return null;
  }

  ImageObject? get selectedImage {
    final id = selectedId.value;
    if (id == null) return null;
    for (final i in _images) {
      if (i.id == id) return i;
    }
    return null;
  }

  ElementObject? get selectedElement {
    final id = selectedId.value;
    if (id == null) return null;
    for (final e in _elements) {
      if (e.id == id) return e;
    }
    return null;
  }

  void select(String? id) => selectedId.value = id;
  void clearSelection() => selectedId.value = null;

  /// Asks the canvas to open the inline editor for [id] on the next frame.
  void requestEdit(String id) => editRequest.value = id;
  void clearEditRequest() => editRequest.value = null;

  @override
  void dispose() {
    selectedId.dispose();
    editRequest.dispose();
    super.dispose();
  }

  // ---- Background -----------------------------------------------------------
  void setBackground(BackgroundState bg) {
    _background = bg;
    notifyListeners();
  }

  // ---- Images ---------------------------------------------------------------
  ImageObject addImage(String path) {
    final n = _images.length;
    final obj = ImageObject(
      id: _generateId(),
      path: path,
      position: Offset(50 + (n % 4) * 22.0, 150 + (n % 4) * 44.0),
    );
    _images.add(obj);
    notifyListeners();
    selectedId.value = obj.id;
    return obj;
  }

  /// A pre-positioned empty frame (from a template) the user taps to add a photo.
  ImageObject addPlaceholderImage({
    required ImageShape shape,
    required Offset position,
    double scale = 1.0,
  }) {
    final obj = ImageObject(
      id: _generateId(),
      path: '',
      shape: shape,
      position: position,
      scale: scale,
      isPlaceholder: true,
    );
    _images.add(obj);
    notifyListeners();
    return obj;
  }

  /// Fills a placeholder (or replaces any image) with a picked photo.
  void fillImage(String id, String path) {
    final i = _images.indexWhere((e) => e.id == id);
    if (i != -1) {
      _images[i] = _images[i].copyWith(path: path, isPlaceholder: false);
      notifyListeners();
    }
  }

  void updateImageTransform(String id,
      {Offset? position, double? scale, double? rotation}) {
    final i = _images.indexWhere((e) => e.id == id);
    if (i != -1) {
      _images[i] = _images[i]
          .copyWith(position: position, scale: scale, rotation: rotation);
      notifyListeners();
    }
  }

  void setImageShape(String id, ImageShape shape) {
    final i = _images.indexWhere((e) => e.id == id);
    if (i != -1) {
      _images[i] = _images[i].copyWith(shape: shape);
      notifyListeners();
    }
  }

  void setImageFrame(String id, {bool? framed, Color? frameColor}) {
    final i = _images.indexWhere((e) => e.id == id);
    if (i != -1) {
      _images[i] = _images[i].copyWith(framed: framed, frameColor: frameColor);
      notifyListeners();
    }
  }

  void deleteImage(String id) {
    if (selectedId.value == id) selectedId.value = null;
    _images.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ---- Text -----------------------------------------------------------------
  TextObject addText([String text = '']) {
    final n = _texts.length;
    final obj = TextObject(
      id: _generateId(),
      text: text,
      // Stagger each new text so they never stack on the exact same spot.
      position: Offset(40 + (n % 3) * 18.0, 170 + (n % 6) * 62.0),
    );
    _texts.add(obj);
    notifyListeners();
    selectedId.value = obj.id;
    return obj;
  }

  void updateText(TextObject updated) {
    final i = _texts.indexWhere((e) => e.id == updated.id);
    if (i != -1) {
      _texts[i] = updated;
      notifyListeners();
    }
  }

  void updateTextContent(String id, String text) {
    final i = _texts.indexWhere((e) => e.id == id);
    if (i != -1) {
      _texts[i] = _texts[i].copyWith(text: text);
      notifyListeners();
    }
  }

  void updateTextTransform(String id,
      {Offset? position, double? scale, double? rotation}) {
    final i = _texts.indexWhere((e) => e.id == id);
    if (i != -1) {
      _texts[i] = _texts[i]
          .copyWith(position: position, scale: scale, rotation: rotation);
      notifyListeners();
    }
  }

  void deleteText(String id) {
    if (selectedId.value == id) selectedId.value = null;
    _texts.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ---- Elements (vector stickers) -------------------------------------------
  ElementObject addElement(ElementShape shape, {Color color = Colors.white}) {
    final n = _elements.length;
    final obj = ElementObject(
      id: _generateId(),
      shape: shape,
      color: color,
      // Stagger so each new element doesn't land on the exact same spot.
      position: Offset(110 + (n % 4) * 20.0, 200 + (n % 5) * 46.0),
    );
    _elements.add(obj);
    notifyListeners();
    selectedId.value = obj.id;
    return obj;
  }

  void updateElementTransform(String id,
      {Offset? position, double? scale, double? rotation}) {
    final i = _elements.indexWhere((e) => e.id == id);
    if (i != -1) {
      _elements[i] = _elements[i]
          .copyWith(position: position, scale: scale, rotation: rotation);
      notifyListeners();
    }
  }

  void setElementColor(String id, Color color) {
    final i = _elements.indexWhere((e) => e.id == id);
    if (i != -1) {
      _elements[i] = _elements[i].copyWith(color: color);
      notifyListeners();
    }
  }

  void setElementStroke(String id, double strokeWidth) {
    final i = _elements.indexWhere((e) => e.id == id);
    if (i != -1) {
      _elements[i] = _elements[i].copyWith(strokeWidth: strokeWidth);
      notifyListeners();
    }
  }

  void deleteElement(String id) {
    if (selectedId.value == id) selectedId.value = null;
    _elements.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ---- Full-status frame ----------------------------------------------------
  void setFrame(StatusFrame frame, {Color? color, double? width}) {
    _frame = frame;
    if (color != null) _frameColor = color;
    if (width != null) _frameWidth = width;
    notifyListeners();
  }

  void setFrameColor(Color color) {
    _frameColor = color;
    notifyListeners();
  }

  void setFrameWidth(double width) {
    _frameWidth = width;
    notifyListeners();
  }
}
