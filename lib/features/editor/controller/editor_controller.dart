import 'package:flutter/material.dart';

/// The five shapes a floating image can take. Nothing else.
enum ImageShape { square, roundedRectangle, circle, oval, heart }

/// A floating image placed on the canvas. Multiple are allowed.
class ImageObject {
  final String id;
  String path; // local gallery file path
  ImageShape shape;
  Offset position; // top-left of the base box, in canvas coordinates
  double scale;
  double rotation; // radians

  ImageObject({
    required this.id,
    required this.path,
    this.shape = ImageShape.roundedRectangle,
    this.position = const Offset(70, 180),
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  ImageObject copyWith({
    String? path,
    ImageShape? shape,
    Offset? position,
    double? scale,
    double? rotation,
  }) {
    return ImageObject(
      id: id,
      path: path ?? this.path,
      shape: shape ?? this.shape,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
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
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}

/// The background can be a solid colour, a gradient (both "built-in"), or a
/// picked gallery image. Only one is active at a time.
class BackgroundState {
  final Color? color;
  final List<Color>? gradientColors;
  final String? imagePath; // gallery file path

  const BackgroundState({this.color, this.gradientColors, this.imagePath});

  bool get isGradient => gradientColors != null && gradientColors!.isNotEmpty;
  bool get isImage => imagePath != null;
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

  void select(String? id) => selectedId.value = id;
  void clearSelection() => selectedId.value = null;

  @override
  void dispose() {
    selectedId.dispose();
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
}
