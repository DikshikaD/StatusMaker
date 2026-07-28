import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/app_navigation.dart';
import 'package:status_maker/core/utils/app_snackbar.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/fixed_templates.dart';
import 'package:status_maker/features/editor/data/status_design.dart';
import 'package:status_maker/features/editor/data/templates_data.dart';
import 'package:status_maker/features/editor/utils/editor_export.dart';
import 'package:status_maker/features/editor/utils/sheet_coordinator.dart';
import 'package:status_maker/features/statuses/data/status_repository.dart';
import 'package:status_maker/shared/widgets/busy_overlay.dart';
import 'package:status_maker/features/editor/presentation/photo_reposition_screen.dart';
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

  /// Set when [initialDesign] uses coordinates authored for a canvas of this
  /// size rather than this device's canvas — i.e. a ready-made fixed template.
  /// The design is scaled onto the real canvas on load so it opens looking the
  /// way it was designed. Null (the default) means the design's coordinates are
  /// already in this canvas's space, so it loads untouched.
  final Size? designCanvasSize;

  const StatusPersonalizerScreen({
    super.key,
    this.templateName = 'Status',
    this.category = '',
    this.template,
    this.initialDesign,
    this.remixOf,
    this.showQuotesOnStart = false,
    this.designCanvasSize,
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
        // Reopen a saved creation exactly as it was — fully editable. A
        // ready-made template comes in with its own canvas coordinates, so map
        // it onto this device's canvas first (this runs post-frame, so the
        // canvas has been laid out and its real size is available).
        final authoredFor = widget.designCanvasSize;
        final toLoad = authoredFor == null
            ? design
            : scaleDesignToCanvas(design, authoredFor, _measureCanvas());
        toLoad.applyTo(_controller);
        _controller.clearSelection();
        // Undo should only ever revert the user's own edits from here on,
        // never back into "before the saved design was loaded".
        _controller.clearHistory();
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
      // Same as above — the initial template/blank-canvas setup shouldn't be
      // something the user can "undo" back into.
      _controller.clearHistory();

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

  /// The canvas's laid-out size. Falls back to the design's own space (i.e. no
  /// scaling) if it can't be measured, which is safer than guessing.
  Size _measureCanvas() {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) return box.size;
    return widget.designCanvasSize ?? kFixedCanvasSize;
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

  /// Opens the pan/zoom adjuster for [id]'s photo — lets the user fix a crop
  /// that's cutting off the part of the photo they actually wanted visible.
  Future<void> _adjustPhoto(String id) async {
    ImageObject? found;
    for (final i in _controller.images) {
      if (i.id == id) {
        found = i;
        break;
      }
    }
    if (found == null || found.path.isEmpty) return;
    // Rebind to a non-nullable `final` — Dart won't keep a nullable local
    // promoted once it's captured inside the `builder:` closure below.
    final image = found;
    final result = await Navigator.push<PhotoAdjustResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoRepositionScreen(image: image),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      _controller.setImagePhotoAdjust(
        id,
        offset: result.offset,
        scale: result.scale,
      );
    }
  }

  void _showElementsSheet() {
    SheetCoordinator.show(
      context,
      builder: (_) => ElementsSheet(
        currentFrame: _controller.frame,
        currentFrameWidth: _controller.frameWidth,
        onAddElement: (shape, color, assetPath) =>
            _controller.addElement(shape, color: color, assetPath: assetPath),
        onSetFrame: (frame, color, width) =>
            _controller.setFrame(frame, color: color, width: width),
        onFrameWidth: _controller.setFrameWidth,
      ),
    );
  }

  void _showQuotesSheet() {
    SheetCoordinator.show(
      context,
      builder: (_) => QuotesSheet(
        category: widget.category,
        onSelect: (quote) => _controller.addText(quote),
      ),
    );
  }

  void _showBackgroundSheet() {
    SheetCoordinator.show(
      context,
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
  ///
  /// Two frames are awaited, not one. Rasterising at 3x and PNG-encoding it
  /// costs long enough to drop frames, so the busy overlay is given a frame of
  /// its own to actually appear first — otherwise the UI locks up while still
  /// showing the untouched editor, which is what makes it feel broken rather
  /// than busy.
  Future<Uint8List?> _capture() async {
    _controller.clearSelection();
    await WidgetsBinding.instance.endOfFrame;
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
    if (_exporting || _busy) return;
    _exporting = true;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes != null) await shareBytes(bytes);
    } finally {
      _exporting = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Save = export the PNG to the device AND store the editable design
  /// privately in the cloud, then close the editor and show the user their new
  /// creation. Only on success — a failed save keeps them here to retry.
  Future<void> _onSave() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      // 1) Keep the existing device export (silent — the cloud save reports).
      await saveToFile(bytes);
      // 2) Persist the editable design to the cloud (private).
      final ok = await _cloudSave(bytes: bytes, makePublic: false);
      // Drop the loader before navigating, so the editor slides away clean
      // instead of carrying a spinner off-screen with it.
      if (mounted) setState(() => _busy = false);
      if (ok) AppNav.goToMyCreations();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Post = store the design publicly, then close the editor and show the Home
  /// feed it was posted to.
  Future<void> _onPost() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      final ok = await _cloudSave(bytes: bytes, makePublic: true);
      // Drop the loader before navigating — see _onSave.
      if (mounted) setState(() => _busy = false);
      if (ok) AppNav.goToHome();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Returns whether the design actually reached the backend, so the caller
  /// only navigates away on success.
  Future<bool> _cloudSave(
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
      return true;
    } catch (_) {
      // Never surface raw backend errors to users — keep it friendly.
      _fail(S.t('something_wrong'));
      return false;
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
            // Loader — sits outside the canvas's RepaintBoundary, so it's never
            // captured into the exported image.
            Positioned.fill(child: BusyOverlay(busy: _busy)),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    // Back + Undo + Redo + 3 action pills is a lot to fit on one row. Text
    // labels on the pills only reliably fit on large screens (tablets) —
    // on a normal phone width they're the difference between this row and
    // an overflow, so this measures the row's own available width instead of
    // guessing from screen size, and drops to icon-only pills (still fully
    // functional, with a Tooltip for discoverability) whenever labels
    // wouldn't fit.
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 6.h, 12.w, 6.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showLabels = constraints.maxWidth >= 430.w;
          return Row(
            children: [
              _iconBtn(
                Icons.arrow_back,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              // Rebuilds on every controller change so the enabled/disabled
              // state always matches whether there's anything to undo/redo.
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Row(
                  children: [
                    _iconBtn(
                      Icons.undo,
                      tooltip: S.t('undo'),
                      onPressed: _controller.canUndo ? _controller.undo : null,
                    ),
                    _iconBtn(
                      Icons.redo,
                      tooltip: S.t('redo'),
                      onPressed: _controller.canRedo ? _controller.redo : null,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _pill(
                label: S.t('save'),
                icon: Icons.download_rounded,
                filled: false,
                showLabel: showLabels,
                onTap: _busy ? null : _onSave,
              ),
              SizedBox(width: 6.w),
              _pill(
                label: S.t('post'),
                icon: Icons.public,
                filled: false,
                showLabel: showLabels,
                onTap: _busy ? null : _onPost,
              ),
              SizedBox(width: 6.w),
              _pill(
                label: S.t('share'),
                icon: Icons.ios_share,
                filled: true,
                showLabel: showLabels,
                onTap: _busy ? null : _share,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Compact icon button for the top bar (back/undo/redo) — smaller than
  /// Flutter's default 48dp IconButton so five of them plus three pills can
  /// actually share one row on a phone-width screen.
  Widget _iconBtn(
    IconData icon, {
    required VoidCallback? onPressed,
    String? tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, color: AppColors.textPrimary, size: 20.w),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
      visualDensity: VisualDensity.compact,
    );
  }

  /// A top-bar action pill. Deliberately has no busy state of its own: while an
  /// action is running the pill just dims (it's disabled), and the single loader
  /// in the middle of the screen is what reports progress.
  Widget _pill({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback? onTap,
    bool showLabel = true,
  }) {
    final disabled = onTap == null;
    final content = Container(
      padding: EdgeInsets.symmetric(
          horizontal: showLabel ? 14.w : 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: filled ? AppColors.accent : AppColors.cardLight,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 18.w,
              color: filled ? Colors.white : AppColors.textPrimary),
          if (showLabel) ...[
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                  color: filled ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp),
            ),
          ],
        ],
      ),
    );
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: showLabel ? content : Tooltip(message: label, child: content),
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
            onAdjust: img.isPlaceholder || img.path.isEmpty
                ? null
                : () => _adjustPhoto(img.id),
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
