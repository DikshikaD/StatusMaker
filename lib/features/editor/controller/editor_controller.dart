import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/data/template_motif.dart';

/// Layout width a text object uses until the user resizes it by hand. Also the
/// value every pre-`boxWidth` saved design deserializes to, so old designs are
/// unaffected by the field being added.
const double kDefaultTextBoxWidth = 300;

/// How far a text box may be narrowed/widened by dragging a corner handle, in
/// the object's own unscaled space. The floor keeps the box wide enough to
/// stay grabbable; the ceiling stops a drag from running away off-canvas.
const double kMinTextBoxWidth = 48;
const double kMaxTextBoxWidth = 1200;

/// Bounds for every object's uniform [scale]. Shared by the pinch gesture and
/// the corner resize handles so both agree on what "as small/large as it goes"
/// means — otherwise one path can leave an object at a size the other refuses
/// to reproduce.
const double kMinObjectScale = 0.3;
const double kMaxObjectScale = 6.0;

/// Padding between an object's content and its selection border. The inline
/// text editor must use the same value as [TransformableObject]: both pivot
/// their rotate/scale transforms on the child's centre, so a mismatch shifts
/// the pivot and makes the text visibly jump when editing starts and ends.
const double kObjectContentPadding = 6;

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

  /// Stacking order across ALL canvas objects (texts, images AND elements
  /// together) — higher paints on top. Without a shared order like this, the
  /// canvas painted (and hit-tested) texts above images above elements no
  /// matter what was actually added or moved on top of what, so once a few
  /// overlapping objects existed, some became impossible to grab at all: taps
  /// landed on whatever object the fixed type-grouping put on top instead.
  /// See EditorController.select(), which bumps this whenever an object is
  /// selected/dragged, bringing it to the front.
  int zIndex;

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
    this.zIndex = 0,
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
    int? zIndex,
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
      zIndex: zIndex ?? this.zIndex,
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

  /// Width of the text box in the object's own (unscaled) coordinate space,
  /// i.e. before [scale] is applied. Null means "never resized by hand" and
  /// falls back to [kDefaultTextBoxWidth] — which is also what every design
  /// saved before this field existed deserializes to, so old designs keep
  /// laying out exactly as they did.
  ///
  /// This is the one dimension a text object resizes freely: dragging a corner
  /// handle re-wraps the text to a new width instead of scaling the glyphs
  /// (font size stays under the user's control via the text toolbar). Images
  /// and stickers have no equivalent — they resize proportionally only, since
  /// stretching a photo or a vector sticker on one axis just distorts it.
  double? boxWidth;

  /// Stacking order across ALL canvas objects — see [ImageObject.zIndex].
  int zIndex;

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
    this.boxWidth,
    this.zIndex = 0,
  });

  /// The width actually used for layout, resolving the "never resized" null.
  double get effectiveBoxWidth => boxWidth ?? kDefaultTextBoxWidth;

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
    double? boxWidth,
    int? zIndex,
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
      boxWidth: boxWidth ?? this.boxWidth,
      zIndex: zIndex ?? this.zIndex,
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

  /// Stacking order across ALL canvas objects — see [ImageObject.zIndex].
  int zIndex;

  ElementObject({
    required this.id,
    required this.shape,
    this.color = Colors.white,
    this.position = const Offset(120, 240),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.strokeWidth = 1.0,
    this.assetPath,
    this.zIndex = 0,
  });

  ElementObject copyWith({
    ElementShape? shape,
    Color? color,
    Offset? position,
    double? scale,
    double? rotation,
    double? strokeWidth,
    String? assetPath,
    int? zIndex,
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
      zIndex: zIndex ?? this.zIndex,
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

  /// Next stacking-order value to hand out — always higher than every zIndex
  /// currently on the canvas, so a freshly added or brought-to-front object is
  /// always painted on top of everything else. Reseeded in [_applySnapshot]
  /// (initial load, undo/redo) so it never collides with values already
  /// baked into a loaded design.
  int _nextZ = 0;

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

  /// Whether the design has edits that aren't in the saved copy yet — drives
  /// the "Discard changes?" prompt on back navigation.
  ///
  /// Driven off [_checkpoint], which is already called by every single mutating
  /// path in this class (add/delete/move/resize/rotate/text/colour/font/
  /// opacity/background/frame). Piggybacking on it rather than setting a flag
  /// in each setter means a mutator added later can't silently forget to mark
  /// the design dirty — it would have to skip undo support too, which is far
  /// more visible. Selection and bring-to-front deliberately don't checkpoint,
  /// so merely tapping an object never counts as an unsaved change.
  ///
  /// A [ValueNotifier] rather than plain state so the back handler can read it
  /// without subscribing to whole-canvas rebuilds.
  final ValueNotifier<bool> isDirty = ValueNotifier<bool>(false);

  /// Marks the current state as the saved baseline — call after a successful
  /// save, so backing out immediately afterwards doesn't re-prompt.
  void markSaved() => isDirty.value = false;

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

  /// Selecting an object also brings it to front (see [ImageObject.zIndex]):
  /// otherwise an object mostly covered by others — easy to end up with once
  /// a few overlap — could be selected via its one exposed sliver but never
  /// actually dragged, since whatever was on top of it would keep intercepting
  /// the drag. Deliberately NOT undoable/checkpointed: it's a side effect of
  /// looking at an object, not an edit.
  void select(String? id) {
    selectedId.value = id;
    if (id != null) _bringToFront(id);
  }

  void clearSelection() => selectedId.value = null;

  /// Raises [id] above everything else, if it isn't already.
  ///
  /// Marks the design dirty even though it doesn't checkpoint. zIndex is
  /// persisted and decides paint (and therefore hit-test) order, so deliberately
  /// tapping overlapping objects into the layering you want IS an edit worth
  /// keeping — without this, arranging three overlapping stickers and backing
  /// out would exit with no prompt and silently lose the arrangement. It still
  /// doesn't checkpoint: undo steps should be the user's explicit edits, not
  /// every incidental tap.
  ///
  /// Reads the frontmost check BEFORE consuming a z value, so re-tapping the
  /// object that's already on top is a genuine no-op rather than burning a
  /// counter slot (and inflating stored z values) on every tap.
  void _bringToFront(String id) {
    void raise<T>(List<T> list, int i, T Function(T, int z) withZ,
        void Function() invalidate) {
      final z = _nextZ++;
      list[i] = withZ(list[i], z);
      invalidate();
      isDirty.value = true;
      notifyListeners();
    }

    final ti = _texts.indexWhere((e) => e.id == id);
    if (ti != -1) {
      if (_isFrontmost(id, _texts[ti].zIndex)) return;
      raise(_texts, ti, (t, z) => t.copyWith(zIndex: z), () => _textsView = null);
      return;
    }
    final ii = _images.indexWhere((e) => e.id == id);
    if (ii != -1) {
      if (_isFrontmost(id, _images[ii].zIndex)) return;
      raise(_images, ii, (t, z) => t.copyWith(zIndex: z), () => _imagesView = null);
      return;
    }
    final ei = _elements.indexWhere((e) => e.id == id);
    if (ei != -1) {
      if (_isFrontmost(id, _elements[ei].zIndex)) return;
      raise(
          _elements, ei, (t, z) => t.copyWith(zIndex: z), () => _elementsView = null);
    }
  }

  /// Whether the object [id] (currently at [z]) already paints above every
  /// other object, so raising it would change nothing.
  ///
  /// Ties count as NOT frontmost. Every object in a design saved before zIndex
  /// existed has z == 0, and _orderedLayers breaks those ties by type grouping
  /// rather than by selection — so treating a tie as "already on top" would
  /// make selecting a buried object in such a design fail to raise it, which is
  /// the exact un-grabbable-overlap problem bring-to-front exists to solve.
  bool _isFrontmost(String id, int z) {
    for (final t in _texts) {
      if (t.id != id && t.zIndex >= z) return false;
    }
    for (final i in _images) {
      if (i.id != id && i.zIndex >= z) return false;
    }
    for (final e in _elements) {
      if (e.id != id && e.zIndex >= z) return false;
    }
    return true;
  }

  /// Asks the canvas to open the inline editor for [id] on the next frame.
  void requestEdit(String id) => editRequest.value = id;
  void clearEditRequest() => editRequest.value = null;

  @override
  void dispose() {
    selectedId.dispose();
    editRequest.dispose();
    isDirty.dispose();
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
    // Reseed above every zIndex this snapshot brought in, so the next add/
    // select can't hand out a value that's already in use and paint behind
    // something it should be on top of.
    var maxZ = -1;
    for (final t in _texts) {
      if (t.zIndex > maxZ) maxZ = t.zIndex;
    }
    for (final i in _images) {
      if (i.zIndex > maxZ) maxZ = i.zIndex;
    }
    for (final e in _elements) {
      if (e.zIndex > maxZ) maxZ = e.zIndex;
    }
    _nextZ = maxZ + 1;
    notifyListeners();
  }

  /// Call immediately before any state mutation, so there's always a snapshot
  /// of "how it looked right before this change" to undo back to.
  void _checkpoint() {
    // Set before the coalescing early-return below, so the 2nd..nth mutation of
    // a rapid burst (e.g. a slider drag, which returns early) still counts.
    isDirty.value = true;
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

  // Undo/redo move the design away from whatever was last saved just as much as
  // a forward edit does, so both mark it dirty. They go through _applySnapshot
  // rather than _checkpoint (which is what normally sets the flag), and
  // _applySnapshot is also how the *initial* load lands — which must NOT count
  // as an edit — so the flag is set here instead of in there.
  void undo() {
    if (_undoStack.isEmpty) return;
    final current = _snapshot();
    final prev = _undoStack.removeLast();
    _redoStack.add(current);
    _lastCheckpointAt = null; // the next edit always gets its own step
    _applySnapshot(prev);
    isDirty.value = true;
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final current = _snapshot();
    final next = _redoStack.removeLast();
    _undoStack.add(current);
    _lastCheckpointAt = null;
    _applySnapshot(next);
    isDirty.value = true;
  }

  /// Called once the editor has finished its initial setup (a fresh canvas, a
  /// preloaded template, or a reopened design) so "Undo" only ever reverts the
  /// user's own edits — never back into a half-built initial state.
  ///
  /// Also resets [isDirty]: that setup runs through the same mutators the user
  /// does, so without this a design would be "unsaved" the instant the editor
  /// opened and backing straight out would wrongly prompt to discard.
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
    _lastCheckpointAt = null;
    isDirty.value = false;
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
      zIndex: _nextZ++,
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
      zIndex: _nextZ++,
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
      zIndex: _nextZ++,
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
      {Offset? position, double? scale, double? rotation, double? boxWidth}) {
    final i = _texts.indexWhere((e) => e.id == id);
    if (i != -1) {
      _checkpoint();
      _texts[i] = _texts[i].copyWith(
        position: position,
        scale: scale,
        rotation: rotation,
        boxWidth: boxWidth,
      );
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
      zIndex: _nextZ++,
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
