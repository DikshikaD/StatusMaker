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

  // Where inside its shape the photo itself is panned/zoomed to — independent
  // of `position`/`scale` above, which move the whole shaped frame on the
  // canvas. Lets the user choose which part of the photo shows instead of
  // always getting BoxFit.cover's auto-centred crop. photoScale is always
  // >= 1.0 (1.0 = the default cover fit, no extra zoom); photoOffset is a pan
  // in the shape's own (unscaled) pixel space, clamped so it can't reveal
  // empty space at the edges.
  Offset photoOffset;
  double photoScale;

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
    this.photoOffset = Offset.zero,
    this.photoScale = 1.0,
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
    Offset? photoOffset,
    double? photoScale,
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
      photoOffset: photoOffset ?? this.photoOffset,
      photoScale: photoScale ?? this.photoScale,
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
/// All are drawn in code by [ElementPainter] — no image assets needed, and
/// (unlike emoji) every sticker recolors to match whatever the user picks in
/// the colour row.
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
  balloon,
  gift,
  crown,
  moon,
  cloud,
  bolt,
  leaf,
  musicNote,
  ribbon,
  confetti,
  // Expressive "character" stickers (WhatsApp-sticker style) — a face drawn
  // on top of the base shape, shown in their own "Stickers" tab in
  // ElementsSheet, separate from the plain single-tone shapes above.
  happySun,
  winkStar,
  blushHeart,
  sleepyMoon,
  waveHand,
  partyPopper,
  catFace,
  heartEyesFace,
  // Marker for a real illustrated sticker image (see ElementObject.assetPath)
  // — never actually drawn by ElementPainter, [EditableElementWidget] renders
  // the image instead. Exists only so `assetPath != null` always pairs with
  // an explicit, self-documenting shape rather than an arbitrary one.
  imageSticker,
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

  /// Set only when [shape] is [ElementShape.imageSticker] — a bundled
  /// illustrated sticker (e.g. `assets/stickers/heart-eyes.png`), rendered as
  /// an image instead of drawn by ElementPainter. Null for every code-drawn
  /// shape/character sticker above.
  String? assetPath;

  ElementObject({
    required this.id,
    required this.shape,
    this.color = Colors.white,
    this.position = const Offset(120, 240),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.strokeWidth = 1.0,
    this.assetPath,
  });

  ElementObject copyWith({
    ElementShape? shape,
    Color? color,
    Offset? position,
    double? scale,
    double? rotation,
    double? strokeWidth,
    String? assetPath,
  }) {
    return ElementObject(
      id: id,
      shape: shape ?? this.shape,
      color: color ?? this.color,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      assetPath: assetPath ?? this.assetPath,
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

/// One point-in-time copy of everything undo/redo needs to restore.
class _EditorSnapshot {
  final BackgroundState background;
  final List<TextObject> texts;
  final List<ImageObject> images;
  final List<ElementObject> elements;
  final StatusFrame frame;
  final Color frameColor;
  final double frameWidth;

  _EditorSnapshot({
    required this.background,
    required this.texts,
    required this.images,
    required this.elements,
    required this.frame,
    required this.frameColor,
    required this.frameWidth,
  });
}

class EditorController extends ChangeNotifier {
  int _seq = 0;
  String _generateId() => '${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  BackgroundState _background = const BackgroundState(color: Color(0xFF0F172A));
  BackgroundState get background => _background;

  // The canvas reads .images/.texts/.elements on every rebuild (which fires on
  // every controller change, including once per frame while a slider like
  // font-size is being dragged). List.unmodifiable() copies the whole list on
  // every call, so without caching this allocates 3 fresh lists per frame
  // regardless of whether that particular list changed. Caching the view and
  // invalidating only when its own backing list mutates avoids that churn.
  final List<ImageObject> _images = [];
  List<ImageObject>? _imagesView;
  List<ImageObject> get images => _imagesView ??= List.unmodifiable(_images);

  final List<TextObject> _texts = [];
  List<TextObject>? _textsView;
  List<TextObject> get texts => _textsView ??= List.unmodifiable(_texts);

  final List<ElementObject> _elements = [];
  List<ElementObject>? _elementsView;
  List<ElementObject> get elements =>
      _elementsView ??= List.unmodifiable(_elements);

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

  // ---- Undo / redo ------------------------------------------------------------
  // A snapshot of everything loadDesign() restores. Kept private and internal
  // to the controller (rather than reusing StatusDesign) to avoid a circular
  // import between this file and status_design.dart, which already depends on
  // the types defined here.
  final List<_EditorSnapshot> _undoStack = [];
  final List<_EditorSnapshot> _redoStack = [];
  static const int _maxHistory = 30;

  // Rapid-fire mutations within this window (e.g. every tick of a slider drag,
  // which calls its setter dozens of times a second) collapse into a single
  // undo step, so dragging one slider takes one "Undo" tap to reverse, not
  // dozens. Discrete taps (add/delete/color/shape) are naturally spaced out
  // well beyond this window, so each still gets its own step.
  static const Duration _coalesceWindow = Duration(milliseconds: 350);
  DateTime? _lastCheckpointAt;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  _EditorSnapshot _snapshot() => _EditorSnapshot(
        background: _background,
        texts: _texts.map((t) => t.copyWith()).toList(),
        images: _images.map((i) => i.copyWith()).toList(),
        elements: _elements.map((e) => e.copyWith()).toList(),
        frame: _frame,
        frameColor: _frameColor,
        frameWidth: _frameWidth,
      );

  void _applySnapshot(_EditorSnapshot snap) {
    _background = snap.background;
    _texts
      ..clear()
      ..addAll(snap.texts);
    _images
      ..clear()
      ..addAll(snap.images);
    _elements
      ..clear()
      ..addAll(snap.elements);
    _frame = snap.frame;
    _frameColor = snap.frameColor;
    _frameWidth = snap.frameWidth;
    selectedId.value = null;
    editRequest.value = null;
    _textsView = null;
    _imagesView = null;
    _elementsView = null;
    notifyListeners();
  }

  /// Call immediately before any state mutation, so there's always a snapshot
  /// of "how it looked right before this change" to undo back to.
  void _checkpoint() {
    final now = DateTime.now();
    if (_lastCheckpointAt != null &&
        now.difference(_lastCheckpointAt!) < _coalesceWindow) {
      _lastCheckpointAt = now;
      return;
    }
    _lastCheckpointAt = now;
    _undoStack.add(_snapshot());
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final current = _snapshot();
    final prev = _undoStack.removeLast();
    _redoStack.add(current);
    _lastCheckpointAt = null; // the next edit always gets its own step
    _applySnapshot(prev);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final current = _snapshot();
    final next = _redoStack.removeLast();
    _undoStack.add(current);
    _lastCheckpointAt = null;
    _applySnapshot(next);
  }

  /// Called once the editor has finished its initial setup (a fresh canvas, a
  /// preloaded template, or a reopened design) so "Undo" only ever reverts the
  /// user's own edits — never back into a half-built initial state.
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    _lastCheckpointAt = null;
  }

  /// Replaces the entire canvas with a previously saved design. Used when the
  /// user opens one of their statuses, or remixes someone else's shared status
  /// (the caller supplies a fresh copy so the original is never mutated).
  void loadDesign({
    required BackgroundState background,
    required List<TextObject> texts,
    required List<ImageObject> images,
    required List<ElementObject> elements,
    StatusFrame frame = StatusFrame.none,
    Color frameColor = Colors.white,
    double frameWidth = 1.0,
  }) {
    _applySnapshot(_EditorSnapshot(
      background: background,
      texts: texts,
      images: images,
      elements: elements,
      frame: frame,
      frameColor: frameColor,
      frameWidth: frameWidth,
    ));
  }

  // ---- Background -----------------------------------------------------------
  void setBackground(BackgroundState bg) {
    _checkpoint();
    _background = bg;
    notifyListeners();
  }

  // ---- Images ---------------------------------------------------------------
  ImageObject addImage(String path) {
    _checkpoint();
    final n = _images.length;
    final obj = ImageObject(
      id: _generateId(),
      path: path,
      position: Offset(50 + (n % 4) * 22.0, 150 + (n % 4) * 44.0),
    );
    _images.add(obj);
    _imagesView = null;
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
    _checkpoint();
    final obj = ImageObject(
      id: _generateId(),
      path: '',
      shape: shape,
      position: position,
      scale: scale,
      isPlaceholder: true,
    );
    _images.add(obj);
    _imagesView = null;
    notifyListeners();
    return obj;
  }

  /// Fills a placeholder (or replaces any image) with a picked photo.
  void fillImage(String id, String path) {
    final i = _images.indexWhere((e) => e.id == id);
    if (i != -1) {
      _checkpoint();
      _images[i] = _images[i].copyWith(path: path, isPlaceholder: false);
      _imagesView = null;
      notifyListeners();
    }
  }

  void updateImageTransform(String id,
      {Offset? position, double? scale, double? rotation}) {
    final i = _images.indexWhere((e) => e.id == id);
    if (i != -1) {
      _checkpoint();
      _images[i] = _images[i]
          .copyWith(position: position, scale: scale, rotation: rotation);
      _imagesView = null;
      notifyListeners();
    }
  }

  void setImageShape(String id, ImageShape shape) {
    final i = _images.indexWhere((e) => e.id == id);
    if (i != -1) {
      _checkpoint();
      _images[i] = _images[i].copyWith(shape: shape);
      _imagesView = null;
      notifyListeners();
    }
  }

  void setImageFrame(String id, {bool? framed, Color? frameColor}) {
    final i = _images.indexWhere((e) => e.id == id);
    if (i != -1) {
      _checkpoint();
      _images[i] = _images[i].copyWith(framed: framed, frameColor: frameColor);
      _imagesView = null;
      notifyListeners();
    }
  }

  /// Applies a new pan/zoom for the photo *inside* its shape (from the photo
  /// reposition screen) — separate from the shape's own position/scale on the
  /// canvas.
  void setImagePhotoAdjust(String id, {Offset? offset, double? scale}) {
    final i = _images.indexWhere((e) => e.id == id);
    if (i != -1) {
      _checkpoint();
      _images[i] =
          _images[i].copyWith(photoOffset: offset, photoScale: scale);
      _imagesView = null;
      notifyListeners();
    }
  }

  void deleteImage(String id) {
    _checkpoint();
    if (selectedId.value == id) selectedId.value = null;
    _images.removeWhere((e) => e.id == id);
    _imagesView = null;
    notifyListeners();
  }

  // ---- Text -----------------------------------------------------------------
  TextObject addText([String text = '']) {
    _checkpoint();
    final n = _texts.length;
    final obj = TextObject(
      id: _generateId(),
      text: text,
      // Stagger each new text so they never stack on the exact same spot.
      position: Offset(40 + (n % 3) * 18.0, 170 + (n % 6) * 62.0),
    );
    _texts.add(obj);
    _textsView = null;
    notifyListeners();
    selectedId.value = obj.id;
    return obj;
  }

  void updateText(TextObject updated) {
    final i = _texts.indexWhere((e) => e.id == updated.id);
    if (i != -1) {
      _checkpoint();
      _texts[i] = updated;
      _textsView = null;
      notifyListeners();
    }
  }

  void updateTextContent(String id, String text) {
    final i = _texts.indexWhere((e) => e.id == id);
    if (i != -1) {
      _checkpoint();
      _texts[i] = _texts[i].copyWith(text: text);
      _textsView = null;
      notifyListeners();
    }
  }

  void updateTextTransform(String id,
      {Offset? position, double? scale, double? rotation}) {
    final i = _texts.indexWhere((e) => e.id == id);
    if (i != -1) {
      _checkpoint();
      _texts[i] = _texts[i]
          .copyWith(position: position, scale: scale, rotation: rotation);
      _textsView = null;
      notifyListeners();
    }
  }

  void deleteText(String id) {
    _checkpoint();
    if (selectedId.value == id) selectedId.value = null;
    _texts.removeWhere((e) => e.id == id);
    _textsView = null;
    notifyListeners();
  }

  // ---- Elements (vector stickers) -------------------------------------------
  ElementObject addElement(
    ElementShape shape, {
    Color color = Colors.white,
    String? assetPath,
  }) {
    _checkpoint();
    final n = _elements.length;
    final obj = ElementObject(
      id: _generateId(),
      shape: shape,
      color: color,
      assetPath: assetPath,
      // Stagger so each new element doesn't land on the exact same spot.
      position: Offset(110 + (n % 4) * 20.0, 200 + (n % 5) * 46.0),
    );
    _elements.add(obj);
    _elementsView = null;
    notifyListeners();
    selectedId.value = obj.id;
    return obj;
  }

  void updateElementTransform(String id,
      {Offset? position, double? scale, double? rotation}) {
    final i = _elements.indexWhere((e) => e.id == id);
    if (i != -1) {
      _checkpoint();
      _elements[i] = _elements[i]
          .copyWith(position: position, scale: scale, rotation: rotation);
      _elementsView = null;
      notifyListeners();
    }
  }

  void setElementColor(String id, Color color) {
    final i = _elements.indexWhere((e) => e.id == id);
    if (i != -1) {
      _checkpoint();
      _elements[i] = _elements[i].copyWith(color: color);
      _elementsView = null;
      notifyListeners();
    }
  }

  void setElementStroke(String id, double strokeWidth) {
    final i = _elements.indexWhere((e) => e.id == id);
    if (i != -1) {
      _checkpoint();
      _elements[i] = _elements[i].copyWith(strokeWidth: strokeWidth);
      _elementsView = null;
      notifyListeners();
    }
  }

  void deleteElement(String id) {
    _checkpoint();
    if (selectedId.value == id) selectedId.value = null;
    _elements.removeWhere((e) => e.id == id);
    _elementsView = null;
    notifyListeners();
  }

  // ---- Full-status frame ----------------------------------------------------
  void setFrame(StatusFrame frame, {Color? color, double? width}) {
    _checkpoint();
    _frame = frame;
    if (color != null) _frameColor = color;
    if (width != null) _frameWidth = width;
    notifyListeners();
  }

  void setFrameColor(Color color) {
    _checkpoint();
    _frameColor = color;
    notifyListeners();
  }

  void setFrameWidth(double width) {
    _checkpoint();
    _frameWidth = width;
    notifyListeners();
  }
}
