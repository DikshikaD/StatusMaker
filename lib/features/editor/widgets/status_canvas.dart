import 'package:flutter/material.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/utils/text_style_builder.dart';
import 'package:status_maker/features/editor/widgets/template_background.dart';
import 'package:status_maker/features/editor/widgets/editable_image_widget.dart';
import 'package:status_maker/features/editor/widgets/editable_element_widget.dart';
import 'package:status_maker/features/editor/widgets/editable_text_widget.dart';
import 'package:status_maker/features/editor/widgets/frame_painter.dart';

/// The editing surface. Wrapped in a RepaintBoundary ([repaintKey]) so Save /
/// Share can capture exactly what's on the status — nothing else.
class StatusCanvas extends StatefulWidget {
  final EditorController controller;
  final GlobalKey repaintKey;

  const StatusCanvas({
    super.key,
    required this.controller,
    required this.repaintKey,
  });

  @override
  State<StatusCanvas> createState() => _StatusCanvasState();
}

class _StatusCanvasState extends State<StatusCanvas> {
  String? _editingId;
  final TextEditingController _editController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.editRequest.addListener(_onEditRequest);
    _focusNode.addListener(_onFocusChange);
  }

  /// Opens the inline editor when the controller asks (e.g. right after the
  /// user taps "Text" and we want the keyboard to appear immediately).
  void _onEditRequest() {
    final id = widget.controller.editRequest.value;
    if (id == null) return;
    widget.controller.clearEditRequest();
    TextObject? target;
    for (final t in widget.controller.texts) {
      if (t.id == id) {
        target = t;
        break;
      }
    }
    if (target == null) return;
    final t = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startEditing(t);
    });
  }

  @override
  void dispose() {
    // Don't lose an in-progress edit if the route is torn down mid-typing.
    _focusNode.removeListener(_onFocusChange);
    _commitEditing(rebuild: false);
    widget.controller.editRequest.removeListener(_onEditRequest);
    _editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing(TextObject t) {
    widget.controller.select(t.id);
    _editController.text = t.text;
    _editController.selection =
        TextSelection.collapsed(offset: _editController.text.length);
    setState(() => _editingId = t.id);
  }

  /// Commits whatever is in the inline editor back to the controller.
  ///
  /// [rebuild] must be false when called from [dispose] — setState is illegal
  /// there. The parent owns the controller and disposes it after its children,
  /// so writing to it from here is still safe.
  void _commitEditing({bool rebuild = true}) {
    final id = _editingId;
    if (id == null) return;
    // Closing a text with no content removes it, instead of leaving a blank.
    if (_editController.text.trim().isEmpty) {
      widget.controller.deleteText(id);
    } else {
      widget.controller.updateTextContent(id, _editController.text);
    }
    _editingId = null;
    if (rebuild) setState(() {});
  }

  /// The IME can be dismissed without ever firing onEditingComplete or
  /// onTapOutside — Android's system back does exactly that. Without this the
  /// typed text is never written back, isDirty is never set, and the next back
  /// press pops the editor with no discard prompt and the edit silently lost.
  void _onFocusChange() {
    if (!_focusNode.hasFocus) _commitEditing();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return RepaintBoundary(
      key: widget.repaintKey,
      // The canvas's real laid-out size on this device — it varies with screen
      // width, and changes on rotation/resize. Objects need it to clamp
      // dragging to the canvas, so it's measured here rather than assumed from
      // the 360x640 design space (which is only the authoring coordinate
      // system, not what anything is actually laid out at).
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canvasSize = constraints.biggest;
          return Stack(
            fit: StackFit.expand,
            children: [
              TemplateBackground(
                state: c.background,
                onTap: () {
                  _commitEditing();
                  c.clearSelection();
                },
              ),

              // Elements, images and texts share ONE stacking order (zIndex) so
              // paint order (and therefore hit-test order) matches whatever the
              // user actually layered on top of what, instead of always
              // painting every text above every image above every element
              // regardless of what was added or dragged where. Without this, an
              // element mostly covered by an image/text placed on top of it
              // could become impossible to grab at all once a few objects
              // overlapped — exactly the "stuck" symptom this fixes. See
              // EditorController.zIndex.
              ..._orderedLayers(c, canvasSize),

              // Full-status decorative frame — always on top, never interactive.
              if (c.frame != StatusFrame.none)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: FramePainter(
                        frame: c.frame,
                        color: c.frameColor,
                        width: c.frameWidth,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Elements, images and texts merged into one list, ordered by zIndex —
  /// ties (e.g. every object in a design saved before zIndex existed, which
  /// all default to 0) fall back to the original elements-then-images-then-
  /// texts grouping, in each list's own order, so old designs keep rendering
  /// exactly as before.
  List<Widget> _orderedLayers(EditorController c, Size canvasSize) {
    final layers = <(int, int, int, Widget)>[
      for (var i = 0; i < c.elements.length; i++)
        (c.elements[i].zIndex, 0, i, _elementLayer(c, c.elements[i], canvasSize)),
      for (var i = 0; i < c.images.length; i++)
        (c.images[i].zIndex, 1, i, _imageLayer(c, c.images[i], canvasSize)),
      for (var i = 0; i < c.texts.length; i++)
        (c.texts[i].zIndex, 2, i, _textLayer(c, c.texts[i], canvasSize)),
    ]..sort((a, b) {
        final z = a.$1.compareTo(b.$1);
        if (z != 0) return z;
        final t = a.$2.compareTo(b.$2);
        if (t != 0) return t;
        return a.$3.compareTo(b.$3);
      });
    return [for (final l in layers) l.$4];
  }

  Widget _elementLayer(EditorController c, ElementObject el, Size canvasSize) {
    return ValueListenableBuilder<String?>(
      key: ValueKey('el_${el.id}'),
      valueListenable: c.selectedId,
      builder: (context, sel, _) {
        return EditableElementWidget(
          element: el,
          isSelected: sel == el.id,
          canvasSize: canvasSize,
          onSelect: () => c.select(el.id),
          onDelete: () => c.deleteElement(el.id),
          onTransformEnd: (p, s, r, _) => c.updateElementTransform(
            el.id,
            position: p,
            scale: s,
            rotation: r,
          ),
        );
      },
    );
  }

  Widget _imageLayer(EditorController c, ImageObject img, Size canvasSize) {
    return ValueListenableBuilder<String?>(
      key: ValueKey('img_${img.id}'),
      valueListenable: c.selectedId,
      builder: (context, sel, _) {
        return EditableImageWidget(
          image: img,
          isSelected: sel == img.id,
          canvasSize: canvasSize,
          onSelect: () => c.select(img.id),
          onDelete: () => c.deleteImage(img.id),
          onTransformEnd: (p, s, r, _) => c.updateImageTransform(
            img.id,
            position: p,
            scale: s,
            rotation: r,
          ),
        );
      },
    );
  }

  Widget _textLayer(EditorController c, TextObject t, Size canvasSize) {
    if (_editingId == t.id) return _buildInlineEditor(t);
    return ValueListenableBuilder<String?>(
      key: ValueKey('txt_${t.id}'),
      valueListenable: c.selectedId,
      builder: (context, sel, _) {
        return EditableTextWidget(
          textObject: t,
          isSelected: sel == t.id,
          canvasSize: canvasSize,
          onSelect: () => c.select(t.id),
          onDelete: () => c.deleteText(t.id),
          onEdit: () => _startEditing(t),
          onTransformEnd: (p, s, r, w) => c.updateTextTransform(
            t.id,
            position: p,
            scale: s,
            rotation: r,
            boxWidth: w,
          ),
        );
      },
    );
  }

  Widget _buildInlineEditor(TextObject t) {
    return Positioned(
      key: ValueKey('editing_${t.id}'),
      left: t.position.dx,
      top: t.position.dy,
      child: Transform.rotate(
        angle: t.rotation,
        child: Transform.scale(
          scale: t.scale,
          child: Padding(
            // Must match TransformableObject's content padding — see
            // kObjectContentPadding. A different value here shifts the
            // transform pivot and the text jumps when editing begins.
            padding: const EdgeInsets.all(kObjectContentPadding),
            child: ConstrainedBox(
            // Same width the object lays out at normally, so switching into
            // and out of editing never re-wraps the text under the cursor.
            constraints: BoxConstraints(maxWidth: t.effectiveBoxWidth),
            child: IntrinsicWidth(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: t.highlight != null
                    ? BoxDecoration(
                        color: t.highlight,
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: TextField(
                  controller: _editController,
                  focusNode: _focusNode,
                  autofocus: true,
                  maxLines: null,
                  textAlign: t.textAlign,
                  cursorColor: t.color,
                  style: buildTextStyle(t),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onEditingComplete: _commitEditing,
                  onTapOutside: (_) => _commitEditing(),
                ),
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
