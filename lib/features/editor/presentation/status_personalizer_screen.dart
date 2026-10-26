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
import 'package:status_maker/shared/utils/native_share.dart';
import 'package:status_maker/shared/widgets/busy_overlay.dart';
import 'package:status_maker/shared/widgets/share_target_dialog.dart';
import 'package:status_maker/features/editor/presentation/photo_reposition_screen.dart';
import 'package:status_maker/features/editor/widgets/discard_changes_dialog.dart';
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

  /// When reopening the user's OWN saved creation to edit, its row id. Saves
  /// then update that row in place instead of inserting a duplicate. Mutually
  /// exclusive with [remixOf] — a status is either yours (edit) or someone
  /// else's (remix), never both.
  final String? existingId;

  /// When true, the quote suggestions sheet is opened automatically once the
  /// editor has loaded — used by the "Create" flow after a category is chosen.
  final bool showQuotesOnStart;

  /// Overrides [StatusDesign.canvasSize] when [initialDesign] uses coordinates
  /// authored for a canvas of this size rather than whatever it recorded
  /// itself — i.e. a ready-made fixed template. Null (the default) just uses
  /// the design's own recorded [StatusDesign.canvasSize].
  final Size? designCanvasSize;

  const StatusPersonalizerScreen({
    super.key,
    this.templateName = 'Status',
    this.category = '',
    this.template,
    this.initialDesign,
    this.remixOf,
    this.existingId,
    this.showQuotesOnStart = false,
    this.designCanvasSize,
  }) : assert(remixOf == null || existingId == null,
            'A status is either your own (existingId) or a remix (remixOf)');

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

  /// Fingerprint of the design as it was handed to us, set **only** when this
  /// editor was opened on someone else's public status (i.e. [widget.remixOf]
  /// is set — see [_isUntouchedRemix]). Null for a blank canvas, a ready-made
  /// template, or the user reopening their own creation; those all post freely.
  String? _remixBaseline;

  @override
  void initState() {
    super.initState();
    // Editing an own creation: seed the row id so the first Save/Post already
    // updates that row instead of inserting a duplicate.
    _statusId = widget.existingId;
    _controller = EditorController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final design = widget.initialDesign;
      final t = widget.template;
      if (design != null) {
        // Reopen a saved creation exactly as it was — fully editable. Every
        // design carries the canvas size it was authored against (explicitly
        // for a ready-made template via widget.designCanvasSize, otherwise
        // whatever device saved it, via design.canvasSize) — map it onto this
        // device's actual canvas before loading (this runs post-frame, so the
        // canvas has been laid out and its real size is available). When the
        // two sizes already match, scaleDesignToCanvas is a no-op.
        final authoredFor = widget.designCanvasSize ?? design.canvasSize;
        final toLoad = scaleDesignToCanvas(design, authoredFor, _measureCanvas());
        toLoad.applyTo(_controller);
        _controller.clearSelection();
        // Undo should only ever revert the user's own edits from here on,
        // never back into "before the saved design was loaded".
        _controller.clearHistory();
        if (widget.remixOf != null) {
          // Baseline is taken *after* scaling + loading, so it describes this
          // canvas rather than the original author's device — otherwise every
          // remix on a differently-sized phone would look pre-edited.
          setState(() => _remixBaseline = _currentSignature());
        }
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

  String _currentSignature() =>
      StatusDesign.fromController(_controller, canvasSize: _measureCanvas())
          .contentSignature;

  /// True while this is a byte-for-byte copy of someone else's public status.
  /// Posting it would republish their work under this user's name and ping them
  /// about their own design, so Post stays disabled until something changes.
  ///
  /// Recomputed rather than latched on the first edit, so undoing all the way
  /// back to the original blocks Post again. Cheap enough to run per rebuild:
  /// it stops comparing entirely once [_remixBaseline] is null, which is every
  /// case except an untouched remix. Note this deliberately does not gate Save
  /// or Share — keeping a private copy of a status you liked is fine; it's only
  /// republishing it unchanged that isn't.
  bool get _isUntouchedRemix =>
      _remixBaseline != null && _currentSignature() == _remixBaseline;

  void _explainRemixGate() {
    if (mounted) AppSnackBar.info(context, S.t('remix_change_first'));
  }

  // ---- actions --------------------------------------------------------------
  /// image_picker throws (rather than returning null) on a denied permission
  /// or a second pick while one is open. Treat that as "nothing picked" and
  /// say so, instead of letting it escape as an unhandled error.
  Future<XFile?> _pickGallery({
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    } catch (e) {
      debugPrint('pickImage failed: $e');
      _fail(S.t('photo_pick_failed'));
      return null;
    }
  }

  Future<void> _pickImage() async {
    final x =
        await _pickGallery(
            imageQuality: 90,
            // Downscale huge camera photos on pick: a status never needs more
            // than ~1080p, and this slashes decode memory and file size.
            maxWidth: 1920,
            maxHeight: 1920);
    // Android can destroy the editor while the gallery is foregrounded;
    // _controller is disposed with it, so writing to it would throw.
    if (!mounted) return;
    if (x != null) _controller.addImage(x.path);
  }

  void _addText() {
    // Add an empty text and drop straight into the keyboard — no placeholder.
    final obj = _controller.addText('');
    _controller.requestEdit(obj.id);
  }

  Future<void> _replaceImage(String id) async {
    final x =
        await _pickGallery(
            imageQuality: 90,
            // Downscale huge camera photos on pick: a status never needs more
            // than ~1080p, and this slashes decode memory and file size.
            maxWidth: 1920,
            maxHeight: 1920);
    if (!mounted) return;
    if (x == null) return;
    _controller.fillImage(id, x.path);
    // Straight into pan/zoom: the automatic centred crop rarely frames a
    // face well inside a heart or circle, and the Adjust button was easy to
    // miss. Done keeps the default crop.
    await _adjustPhoto(id);
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
          final x = await _pickGallery(
              imageQuality: 90,
              maxWidth: 1920,
              maxHeight: 1920);
          if (!mounted) return;
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

  /// Share = ask where it's going (WhatsApp / Instagram / Facebook / any other
  /// app), then export and hand the PNG straight to that destination.
  ///
  /// The popup is shown *before* the capture so it opens instantly, and the
  /// loader only covers the export that follows the user's choice.
  Future<void> _share() async {
    if (_exporting || _busy) return;
    final target = await showShareTargetDialog(context);
    if (target == null || !mounted) return;

    _exporting = true;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      await NativeShare.shareImage(
        path: await writeTempPng(bytes),
        target: target,
      );
    } catch (e) {
      debugPrint('share failed: $e');
      _fail(S.t('share_failed'));
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
      // Persist the editable design to the cloud (private).
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
    // Belt and braces: the pill is already disabled in this state, but nothing
    // else may publish an unchanged copy of someone else's status either.
    if (_isUntouchedRemix) {
      _explainRemixGate();
      return;
    }
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

  // ---- unsaved changes ------------------------------------------------------
  /// Guards every way out of the editor: Android's system back, the iOS back
  /// swipe, and the AppBar arrow all funnel through here.
  ///
  /// Returns whether the editor should actually close. Save only closes if the
  /// save succeeded — a failed upload must keep the user here with their work
  /// intact rather than dropping it on the floor.
  Future<bool> _confirmExit() async {
    if (!_controller.isDirty.value) return true; // nothing to lose
    final choice = await showDiscardChangesDialog(context);
    switch (choice) {
      case DiscardChoice.discard:
        return true;
      case DiscardChoice.cancel:
        return false;
      case DiscardChoice.save:
        // _onSave navigates on success by itself (to My Creations), so this
        // must NOT also pop — doing both would tear an extra route off the
        // stack. Reporting "don't close" leaves the navigation entirely to
        // _onSave, and on failure the user simply stays here.
        await _onSave();
        return false;
    }
  }

  /// The AppBar arrow. `Navigator.maybePop` would consult the PopScope below
  /// and prompt twice, so it asks directly and pops only on a yes.
  Future<void> _onBackPressed() async {
    if (!await _confirmExit()) return;
    if (mounted) Navigator.of(context).pop();
  }

  /// Returns whether the design actually reached the backend, so the caller
  /// only navigates away on success.
  Future<bool> _cloudSave(
      {required Uint8List bytes, required bool makePublic}) async {
    try {
      final design =
          StatusDesign.fromController(_controller, canvasSize: _measureCanvas());
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
      // The canvas now matches what's stored, so backing out straight after a
      // save mustn't re-prompt.
      _controller.markSaved();
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

    // Covers Android's system back and the iOS back-swipe. canPop is driven by
    // isDirty so a clean design keeps the native gesture fully interactive
    // (predictive back, swipe-to-dismiss) instead of intercepting a pop that
    // was never in question; only a dirty design blocks and asks.
    return ValueListenableBuilder<bool>(
      valueListenable: _controller.isDirty,
      builder: (context, dirty, child) => PopScope(
        canPop: !dirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return; // canPop was true — nothing to guard
          final leave = await _confirmExit();
          if (!leave || !mounted) return;
          // this.context: the State's own, which is what `mounted` guards.
          Navigator.of(this.context).pop();
        },
        child: child!,
      ),
      // Built once and reused across isDirty flips — the editor's whole subtree
      // has nothing to say about the dirty flag, and rebuilding the canvas
      // every time the design first becomes dirty would be pure waste.
      child: _body(reserved),
    );
  }

  Widget _body(double reserved) {
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
                onPressed: _onBackPressed,
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
              // Post is the one action that can be blocked by the design's
              // *content* (an untouched remix), so unlike Save and Share it has
              // to re-evaluate on every controller change.
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final blocked = _isUntouchedRemix;
                  return _pill(
                    label: S.t('post'),
                    icon: Icons.public,
                    filled: false,
                    showLabel: showLabels,
                    disabled: blocked,
                    // A dead pill just leaves the user tapping at nothing, so a
                    // blocked Post still answers — it explains itself instead.
                    onTap: _busy ? null : (blocked ? _explainRemixGate : _onPost),
                  );
                },
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

    /// Dims the pill *without* swallowing the tap, so an unavailable action can
    /// still say why it's unavailable instead of silently ignoring the user.
    bool disabled = false,
  }) {
    final dim = disabled || onTap == null;
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
      opacity: dim ? 0.5 : 1.0,
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
