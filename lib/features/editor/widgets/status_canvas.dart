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

  void _commitEditing() {
    final id = _editingId;
    if (id == null) return;
    // Closing a text with no content removes it, instead of leaving a blank.
    if (_editController.text.trim().isEmpty) {
      widget.controller.deleteText(id);
    } else {
      widget.controller.updateTextContent(id, _editController.text);
    }
    setState(() => _editingId = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return RepaintBoundary(
      key: widget.repaintKey,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            TemplateBackground(
              state: c.background,
              onTap: () {
                _commitEditing();
                c.clearSelection();
              },
            ),

            // Vector elements (stickers)
            ...c.elements.map((el) {
              return ValueListenableBuilder<String?>(
                key: ValueKey('el_${el.id}'),
                valueListenable: c.selectedId,
                builder: (context, sel, _) {
                  return EditableElementWidget(
                    element: el,
                    isSelected: sel == el.id,
                    onSelect: () => c.select(el.id),
                    onDelete: () => c.deleteElement(el.id),
                    onTransformEnd: (p, s, r) => c.updateElementTransform(
                      el.id,
                      position: p,
                      scale: s,
                      rotation: r,
                    ),
                  );
                },
              );
            }),

            // Floating images
            ...c.images.map((img) {
              return ValueListenableBuilder<String?>(
                key: ValueKey('img_${img.id}'),
                valueListenable: c.selectedId,
                builder: (context, sel, _) {
                  return EditableImageWidget(
                    image: img,
                    isSelected: sel == img.id,
                    onSelect: () => c.select(img.id),
                    onDelete: () => c.deleteImage(img.id),
                    onTransformEnd: (p, s, r) => c.updateImageTransform(
                      img.id,
                      position: p,
                      scale: s,
                      rotation: r,
                    ),
                  );
                },
              );
            }),

            // Texts
            ...c.texts.map((t) {
              if (_editingId == t.id) return _buildInlineEditor(t);
              return ValueListenableBuilder<String?>(
                key: ValueKey('txt_${t.id}'),
                valueListenable: c.selectedId,
                builder: (context, sel, _) {
                  return EditableTextWidget(
                    textObject: t,
                    isSelected: sel == t.id,
                    onSelect: () => c.select(t.id),
                    onDelete: () => c.deleteText(t.id),
                    onEdit: () => _startEditing(t),
                    onTransformEnd: (p, s, r) => c.updateTextTransform(
                      t.id,
                      position: p,
                      scale: s,
                      rotation: r,
                    ),
                  );
                },
              );
            }),

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
        ),
      ),
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
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
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
