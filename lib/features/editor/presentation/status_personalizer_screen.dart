import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/app_snackbar.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/status_design.dart';
import 'package:status_maker/features/editor/data/templates_data.dart';
import 'package:status_maker/features/editor/utils/editor_export.dart';
import 'package:status_maker/features/statuses/data/status_repository.dart';
import 'package:status_maker/features/editor/widgets/status_canvas.dart';
import 'package:status_maker/features/editor/widgets/toolbars/add_bar.dart';
import 'package:status_maker/features/editor/widgets/toolbars/text_toolbar.dart';
import 'package:status_maker/features/editor/widgets/toolbars/image_toolbar.dart';
import 'package:status_maker/features/editor/widgets/toolbars/element_toolbar.dart';
import 'package:status_maker/features/editor/widgets/bottom_sheets/background_sheet.dart';
import 'package:status_maker/features/editor/widgets/bottom_sheets/elements_sheet.dart';
import 'package:status_maker/features/editor/widgets/bottom_sheets/quotes_sheet.dart';
import 'package:status_maker/core/utils/responsive.dart';

class StatusPersonalizerScreen extends StatefulWidget {
  final String templateName;
  final String category;
  final StatusTemplate? template;

  /// A previously saved design to reopen for editing (Customize / remix). When
  /// set it takes priority over [template] and the design is loaded as-is.
  final StatusDesign? initialDesign;

  /// When reopening someone else's public status to customize, the id of the
  /// original — stored as `remix_of` on the new saved row.
  final String? remixOf;

  /// When true, the quote suggestions sheet is opened automatically once the
  /// editor has loaded — used by the "Create" flow after a category is chosen.
  final bool showQuotesOnStart;

  const StatusPersonalizerScreen({
    super.key,
    this.templateName = 'Status',
    this.category = '',
    this.template,
    this.initialDesign,
    this.remixOf,
    this.showQuotesOnStart = false,
  });

  @override
  State<StatusPersonalizerScreen> createState() =>
      _StatusPersonalizerScreenState();
}

class _StatusPersonalizerScreenState extends State<StatusPersonalizerScreen> {
  late final EditorController _controller;
  final GlobalKey _canvasKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();
  final StatusRepository _repo = StatusRepository();
  bool _exporting = false;
  bool _busy = false; // guards the cloud Save/Post actions

  /// Id of the row this design is saved under, so Save→Post (or a second Save)
  /// updates the same creation instead of making duplicates.
  String? _statusId;

  @override
  void initState() {
    super.initState();
    _controller = EditorController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final design = widget.initialDesign;
      final t = widget.template;
      if (design != null) {
        // Reopen a saved creation exactly as it was — fully editable.
        design.applyTo(_controller);
        _controller.clearSelection();
        return;
      }
      if (t != null) {
        // Preload the chosen design — background, motif and styled text — all
        // still fully editable.
        _controller.setBackground(BackgroundState(
          gradientColors: t.gradient,
          motif: t.motif,
          motifColor: t.textColor,
        ));
        if (t.imageShape != null) {
          _controller.addPlaceholderImage(
            shape: t.imageShape!,
            position: t.imagePosition,
            scale: t.imageScale,
          );
        }
        final y = t.anchor == TemplateAnchor.top
            ? 80.0
            : t.anchor == TemplateAnchor.bottom
                ? 430.0
                : 240.0;
        final obj = _controller.addText(t.text);
        _controller.updateText(obj.copyWith(
          fontFamily: t.fontFamily,
          color: t.textColor,
          bold: t.bold,
          fontSize: t.fontSize,
          textAlign: t.align,
          letterSpacing: t.letterSpacing,
          highlight: t.highlight,
          position: Offset(28, y),
        ));
      } else {
        // Start on a clean canvas — no placeholder "tap to edit" text.
        _controller.setBackground(const BackgroundState(
          gradientColors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ));
      }
      _controller.clearSelection();

      // Straight after the canvas is ready, surface category-matched quotes
      // so the user can start from a ready-made line.
      if (widget.showQuotesOnStart && mounted) {
        _showQuotesSheet();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---- actions --------------------------------------------------------------
  Future<void> _pickImage() async {
    final x =
        await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 90,
            // Downscale huge camera photos on pick: a status never needs more
            // than ~1080p, and this slashes decode memory and file size.
            maxWidth: 1920,
            maxHeight: 1920);
    if (x != null) _controller.addImage(x.path);
  }

  void _addText() {
    // Add an empty text and drop straight into the keyboard — no placeholder.
    final obj = _controller.addText('');
    _controller.requestEdit(obj.id);
  }

  Future<void> _replaceImage(String id) async {
    final x =
        await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 90,
            // Downscale huge camera photos on pick: a status never needs more
            // than ~1080p, and this slashes decode memory and file size.
            maxWidth: 1920,
            maxHeight: 1920);
    if (x != null) _controller.fillImage(id, x.path);
  }

  void _showElementsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ElementsSheet(
        currentFrame: _controller.frame,
        currentFrameWidth: _controller.frameWidth,
        onAddElement: (shape, color) =>
            _controller.addElement(shape, color: color),
        onSetFrame: (frame, color, width) =>
            _controller.setFrame(frame, color: color, width: width),
        onFrameWidth: _controller.setFrameWidth,
      ),
    );
  }

  void _showQuotesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuotesSheet(
        category: widget.category,
        onSelect: (quote) => _controller.addText(quote),
      ),
    );
  }

  void _showBackgroundSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BackgroundSheet(
        category: widget.category,
        onSelect: _controller.setBackground,
        onPickGallery: () async {
          Navigator.of(context).pop();
          final x = await _picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 90,
              maxWidth: 1920,
              maxHeight: 1920);
          if (x != null) {
            _controller.setBackground(BackgroundState(imagePath: x.path));
          }
        },
      ),
    );
  }

  /// Deselect, wait a frame so no selection handles are baked in, then
  /// rasterise the canvas to PNG bytes.
  Future<Uint8List?> _capture() async {
    _controller.clearSelection();
    await WidgetsBinding.instance.endOfFrame;
    return captureCanvas(_canvasKey);
  }

  void _ok(String msg) {
    if (mounted) AppSnackBar.success(context, msg);
  }

  void _fail(String msg) {
    if (mounted) AppSnackBar.error(context, msg);
  }

  /// A short title for the saved row — the first line of text on the canvas,
  /// falling back to the category (or a generic label).
  String _deriveTitle() {
    for (final t in _controller.texts) {
      final text = t.text.trim();
      if (text.isNotEmpty) {
        final firstLine = text.split('\n').first.trim();
        return firstLine.length > 60 ? firstLine.substring(0, 60) : firstLine;
      }
    }
    return widget.category.isNotEmpty ? widget.category : 'My Status';
  }

  /// System share sheet (WhatsApp etc.) — unchanged behaviour.
  Future<void> _share() async {
    if (_exporting) return;
    _exporting = true;
    try {
      final bytes = await _capture();
      if (bytes != null) await shareBytes(bytes);
    } finally {
      _exporting = false;
    }
  }

  /// Save = export the PNG to the device AND store the editable design
  /// privately in the cloud (so it shows under "My Creations").
  Future<void> _onSave() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      // 1) Keep the existing device export (silent — the cloud save reports).
      await saveToFile(bytes);
      // 2) Persist the editable design to the cloud (private).
      await _cloudSave(bytes: bytes, makePublic: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Post = store the design publicly so it appears on the Home feed.
  Future<void> _onPost() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      await _cloudSave(bytes: bytes, makePublic: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cloudSave(
      {required Uint8List bytes, required bool makePublic}) async {
    try {
      final design = StatusDesign.fromController(_controller);
      final saved = await _repo.saveDesign(
        design: design,
        thumbnailBytes: bytes,
        title: _deriveTitle(),
        category: widget.category.isEmpty ? null : widget.category,
        makePublic: makePublic,
        existingId: _statusId,
        remixOf: _statusId == null ? widget.remixOf : null,
      );
      _statusId = saved.id;
      _ok(makePublic ? S.t('posted_public') : S.t('saved_cloud'));
    } catch (_) {
      // Never surface raw backend errors to users — keep it friendly.
      _fail(S.t('something_wrong'));
    }
  }

  // ---- ui -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Reserve space for the (collapsed) bottom toolbar so the canvas is laid
    // out once and never moves when the toolbar swaps between add / text /
    // image / element states. Taller toolbars simply overlay the canvas margin.
    final reserved = 128.h + ScreenUtil.bottomBarHeight;

    return Scaffold(
      backgroundColor: AppColors.background,
      // Keep the canvas at full size when the keyboard opens for editing —
      // otherwise the whole editor shrinks/squeezes.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Canvas layer — fixed size, independent of the toolbar's height.
            Column(
              children: [
                _topBar(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: reserved),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 12.h),
                        child: AspectRatio(
                          aspectRatio: 9 / 16,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 24.r,
                                  offset: Offset(0, 10.h),
                                ),
                              ],
                            ),
                            child: AnimatedBuilder(
                              animation: _controller,
                              builder: (_, __) => StatusCanvas(
                                controller: _controller,
                                repaintKey: _canvasKey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Toolbar layer — floats at the bottom, over the canvas margin.
            Align(
              alignment: Alignment.bottomCenter,
              child: _bottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 6.h, 12.w, 6.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          _pill(
            label: S.t('save'),
            icon: Icons.download_rounded,
            filled: false,
            onTap: _busy ? null : _onSave,
          ),
          SizedBox(width: 8.w),
          _pill(
            label: S.t('post'),
            icon: Icons.public,
            filled: false,
            busy: _busy,
            onTap: _busy ? null : _onPost,
          ),
          SizedBox(width: 8.w),
          _pill(
            label: S.t('share'),
            icon: Icons.ios_share,
            filled: true,
            onTap: _busy ? null : _share,
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback? onTap,
    bool busy = false,
  }) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled && !busy ? 0.5 : 1.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: filled ? AppColors.accent : AppColors.cardLight,
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Row(
            children: [
              if (busy)
                SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: filled ? Colors.white : AppColors.textPrimary,
                  ),
                )
              else
                Icon(icon,
                    size: 18.w,
                    color: filled ? Colors.white : AppColors.textPrimary),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                    color: filled ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _controller.selectedId]),
      builder: (context, _) {
        final txt = _controller.selectedText;
        final img = _controller.selectedImage;
        final el = _controller.selectedElement;

        Widget child;
        String key;
        if (txt != null) {
          key = 'text';
          child = TextToolbar(
            text: txt,
            onChanged: _controller.updateText,
          );
        } else if (img != null) {
          key = 'image';
          child = ImageToolbar(
            image: img,
            onShape: (s) => _controller.setImageShape(img.id, s),
            onDelete: () => _controller.deleteImage(img.id),
            onReplace: () => _replaceImage(img.id),
            onToggleFrame: () =>
                _controller.setImageFrame(img.id, framed: !img.framed),
          );
        } else if (el != null) {
          key = 'element';
          child = ElementToolbar(
            element: el,
            onColor: (c) => _controller.setElementColor(el.id, c),
            onStroke: (w) => _controller.setElementStroke(el.id, w),
            onDelete: () => _controller.deleteElement(el.id),
          );
        } else {
          key = 'add';
          child = AddBar(
            onBackground: _showBackgroundSheet,
            onPhoto: _pickImage,
            onText: _addText,
            onQuotes: _showQuotesSheet,
            onElements: _showElementsSheet,
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (c, anim) =>
              FadeTransition(opacity: anim, child: c),
          child: KeyedSubtree(key: ValueKey(key), child: child),
        );
      },
    );
  }
}
