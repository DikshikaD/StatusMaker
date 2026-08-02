import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/app_navigation.dart';
import 'package:status_maker/core/utils/app_snackbar.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/fixed_templates.dart';
import 'package:status_maker/features/editor/data/status_design.dart';
import 'package:status_maker/features/editor/presentation/photo_reposition_screen.dart';
import 'package:status_maker/features/editor/utils/editor_export.dart';
import 'package:status_maker/features/editor/utils/text_style_builder.dart';
import 'package:status_maker/features/editor/widgets/discard_changes_dialog.dart';
import 'package:status_maker/features/editor/widgets/fixed_template_canvas.dart';
import 'package:status_maker/features/editor/widgets/toolbars/locked_toolbars.dart';
import 'package:status_maker/features/statuses/data/status_repository.dart';
import 'package:status_maker/shared/utils/native_share.dart';
import 'package:status_maker/shared/widgets/share_target_dialog.dart';

/// The LOCKED editor for a [FixedTemplate]. The design (positions, fonts,
/// colors, decorations) can't be changed — the user can only:
///  • tap any text to change its words
///  • add / replace / adjust the photo in the template's fixed slot
class TemplateFillScreen extends StatefulWidget {
  final FixedTemplate template;

  const TemplateFillScreen({super.key, required this.template});

  @override
  State<TemplateFillScreen> createState() => _TemplateFillScreenState();
}

class _TemplateFillScreenState extends State<TemplateFillScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();
  final StatusRepository _repo = StatusRepository();

  late List<TextObject> _texts;
  late List<ElementObject> _elements;
  ImageObject? _photo;

  /// Which object the contextual toolbar is acting on, exactly like the free
  /// editor's selection — except here selecting only reveals the applicable
  /// controls; it never lets the object be moved or resized.
  String? _selectedId;

  bool _exporting = false;
  bool _busy = false;
  String? _statusId;

  /// Whether anything has been changed since the last successful save — drives
  /// the "Discard changes?" prompt on the way out.
  ///
  /// A plain field rather than the free editor's EditorController.isDirty:
  /// this screen deliberately doesn't use EditorController at all (the layout
  /// is locked, so there's nothing to move/resize/undo), it just holds the
  /// three lists directly. Every mutation here goes through [_edit], which is
  /// the single place that sets it.
  bool _dirty = false;

  /// Applies a change to the locked design and records it as unsaved. Every
  /// mutator funnels through this rather than calling setState directly, so a
  /// new one can't quietly skip the dirty flag.
  void _edit(VoidCallback change) {
    setState(() {
      change();
      _dirty = true;
    });
  }

  FixedTemplate get _t => widget.template;

  TextObject? get _selectedText {
    for (final t in _texts) {
      if (t.id == _selectedId) return t;
    }
    return null;
  }

  ImageObject? get _selectedPhoto =>
      _photo != null && _photo!.id == _selectedId ? _photo : null;

  void _select(String? id) => setState(() => _selectedId = id);

  /// Selecting the photo slot when it's still empty goes straight to the
  /// picker — that's the only thing an empty slot is for.
  Future<void> _onPhotoTap(ImageObject img) async {
    if (img.isPlaceholder || img.path.isEmpty) {
      _select(img.id);
      await _addOrReplacePhoto();
      return;
    }
    _select(img.id);
  }

  @override
  void initState() {
    super.initState();
    final d = _t.design();
    _texts = d.texts;
    _elements = d.elements;
    _photo = d.images.isNotEmpty ? d.images.first : null;
  }

  /// The current composition — used both for rendering and for saving, so
  /// what's saved is always exactly what's on screen.
  StatusDesign _currentDesign() => StatusDesign(
        background: _t.background,
        texts: _texts,
        images: [if (_photo != null) _photo!],
        elements: _elements,
        frame: _t.frame,
        frameColor: _t.frameColor,
        frameWidth: _t.frameWidth,
      );

  // ---- text editing (words only) -------------------------------------------
  Future<void> _editText(TextObject t, {String? hint}) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _TextEditSheet(textObject: t, hint: hint),
    );
    if (result == null) return;
    final text = result.trim();
    if (text == t.text) return;
    // Clearing a slot is allowed and safe: the layout is fixed, so an empty
    // slot just leaves its space blank instead of reflowing the design (handy
    // for dropping a caption you don't want).
    _edit(() {
      final i = _texts.indexWhere((e) => e.id == t.id);
      if (i != -1) _texts[i] = _texts[i].copyWith(text: text);
    });
  }

  /// Opens the words editor for [t], titled for whichever kind of slot it is.
  /// The name slot opens empty while it still shows its placeholder, so the
  /// user types their name instead of deleting "— Your Name" first.
  Future<void> _editWords(TextObject t) async {
    final isName = t.id == _t.nameSlotId;
    if (isName && t.text == S.t('name_placeholder')) {
      await _editText(t.copyWith(text: ''), hint: S.t('your_name'));
      return;
    }
    await _editText(t, hint: isName ? S.t('your_name') : null);
  }

  /// Applies a style change from the text toolbar. Only properties that can't
  /// change the slot's footprint reach here (font, colour, bold, italic) — see
  /// [LockedTextToolbar].
  void _updateTextStyle(TextObject updated) {
    _edit(() {
      final i = _texts.indexWhere((e) => e.id == updated.id);
      if (i != -1) _texts[i] = updated;
    });
  }

  // ---- photo (fixed slot only) ----------------------------------------------
  Future<String?> _pickPhoto() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    return x?.path;
  }

  /// Fills the template's designed slot — the photo always lands exactly
  /// where the design wants it.
  Future<void> _addOrReplacePhoto() async {
    final proto = _t.photo;
    if (proto == null) return;
    final path = await _pickPhoto();
    if (path == null) return;
    _edit(() {
      _photo = (_photo ?? proto.copyWith()).copyWith(
        path: path,
        isPlaceholder: false,
        // A new picture starts from the default cover crop.
        photoOffset: Offset.zero,
        photoScale: 1.0,
      );
    });
  }

  /// Pan/zoom the picture *inside* its fixed shape — the slot itself never
  /// moves.
  Future<void> _adjustPhoto() async {
    final img = _photo;
    if (img == null || img.path.isEmpty) return;
    final result = await Navigator.push<PhotoAdjustResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoRepositionScreen(image: img),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      _edit(() {
        _photo = img.copyWith(
          photoOffset: result.offset,
          photoScale: result.scale,
        );
      });
    }
  }

  void _removePhoto() {
    _edit(() {
      // Visible slots revert to their "Add photo" frame; hidden overlay slots
      // disappear entirely.
      final proto = _t.photo;
      _photo = _t.showPlaceholder && proto != null ? proto.copyWith() : null;
    });
  }

  /// Toggles the decorative border on the photo — safe to expose because it
  /// paints inside the slot's existing box and can't shift the layout.
  void _toggleFrame() {
    final img = _photo;
    if (img == null) return;
    _edit(() => _photo = img.copyWith(framed: !img.framed));
  }

  // ---- save / post / share ----------------------------------------------------
  /// Deselect first so no selection outline is baked into the export, then wait
  /// a frame for it to actually be gone before rasterising.
  Future<Uint8List?> _capture() async {
    if (_selectedId != null) setState(() => _selectedId = null);
    await WidgetsBinding.instance.endOfFrame;
    return captureCanvas(_canvasKey);
  }

  void _ok(String msg) {
    if (mounted) AppSnackBar.success(context, msg);
  }

  void _fail(String msg) {
    if (mounted) AppSnackBar.error(context, msg);
  }

  String _deriveTitle() {
    for (final t in _texts) {
      final text = t.text.trim();
      if (text.isNotEmpty) {
        final firstLine = text.split('\n').first.trim();
        return firstLine.length > 60 ? firstLine.substring(0, 60) : firstLine;
      }
    }
    return _t.name;
  }

  /// Ask where it's going (WhatsApp / Instagram / Facebook / any other app)
  /// first, then export and hand the PNG straight to that destination. The popup
  /// opens before the capture so it appears instantly.
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
    } finally {
      _exporting = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Save keeps the status private, so it goes to "My Creations". Only on
  /// success — a failed save leaves the user here so they can retry.
  Future<void> _onSave() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      await saveToFile(bytes);
      final ok = await _cloudSave(bytes: bytes, makePublic: false);
      if (ok) AppNav.goToMyCreations();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Post makes it public, so it goes to the Home feed it just landed on.
  Future<void> _onPost() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) return;
      final ok = await _cloudSave(bytes: bytes, makePublic: true);
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
      // Don't persist an unfilled "Add photo" frame into the saved design.
      final design = _currentDesign();
      final cleaned = StatusDesign(
        background: design.background,
        texts: design.texts,
        images: design.images.where((i) => i.path.isNotEmpty).toList(),
        elements: design.elements,
        frame: design.frame,
        frameColor: design.frameColor,
        frameWidth: design.frameWidth,
      );
      final saved = await _repo.saveDesign(
        design: cleaned,
        thumbnailBytes: bytes,
        title: _deriveTitle(),
        makePublic: makePublic,
        existingId: _statusId,
      );
      _statusId = saved.id;
      // What's on the canvas now matches what's stored.
      _dirty = false;
      _ok(makePublic ? S.t('posted_public') : S.t('saved_cloud'));
      return true;
    } catch (_) {
      _fail(S.t('something_wrong'));
      return false;
    }
  }

  // ---- unsaved changes ------------------------------------------------------
  /// Guards Android's system back, the iOS back swipe and the AppBar arrow.
  /// Returns whether the editor should actually close — Save only closes on a
  /// successful save, so a failed upload never costs the user their edits.
  Future<bool> _confirmExit() async {
    if (!_dirty) return true;
    final choice = await showDiscardChangesDialog(context);
    switch (choice) {
      case DiscardChoice.discard:
        return true;
      case DiscardChoice.cancel:
        return false;
      case DiscardChoice.save:
        // _onSave navigates away itself on success; popping here as well would
        // tear an extra route off the stack.
        await _onSave();
        return false;
    }
  }

  /// The AppBar arrow. `Navigator.maybePop` would consult the PopScope below
  /// and prompt twice, so this asks directly and pops only on a yes.
  Future<void> _onBackPressed() async {
    if (!await _confirmExit()) return;
    if (mounted) Navigator.of(context).pop();
  }

  // ---- ui -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Reserve room for the collapsed toolbar so the canvas is laid out once and
    // never jumps when the toolbar swaps between idle / text / photo. Matches
    // the free editor's reservation; taller states simply overlay this margin.
    final reserved = 128.h + ScreenUtil.bottomBarHeight;

    // Covers Android's system back and the iOS back-swipe. An untouched
    // template keeps the native gesture fully interactive; only unsaved edits
    // block the pop and ask.
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return; // canPop was true — nothing to guard
        final leave = await _confirmExit();
        if (!leave || !mounted) return;
        Navigator.of(context).pop();
      },
      child: _body(reserved),
    );
  }

  Widget _body(double reserved) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
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
                            child: FixedTemplateCanvas(
                              design: _currentDesign(),
                              repaintKey: _canvasKey,
                              lineLimits: _t.lineLimits,
                              selectedId: _selectedId,
                              onTextTap: (t) => _select(t.id),
                              onTextDoubleTap: _editWords,
                              onPhotoTap: _onPhotoTap,
                              onBackgroundTap: () => _select(null),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
            icon: Icon(Icons.arrow_back,
                color: AppColors.textPrimary, size: 20.w),
            onPressed: _onBackPressed,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              _t.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _pill(
            label: S.t('save'),
            icon: Icons.download_rounded,
            filled: false,
            onTap: _busy ? null : _onSave,
          ),
          SizedBox(width: 6.w),
          _pill(
            label: S.t('post'),
            icon: Icons.public,
            filled: false,
            busy: _busy,
            onTap: _busy ? null : _onPost,
          ),
          SizedBox(width: 6.w),
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
        child: Tooltip(
          message: label,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: filled ? AppColors.accent : AppColors.cardLight,
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: busy
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: filled ? Colors.white : AppColors.textPrimary,
                    ),
                  )
                : Icon(icon,
                    size: 18.w,
                    color: filled ? Colors.white : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  /// Contextual toolbar, exactly like the free editor's: it swaps to match
  /// whatever is selected, and shows only the controls that apply to a locked
  /// design. Nothing here can move, resize or delete an object.
  Widget _bottomBar() {
    final txt = _selectedText;
    final img = _selectedPhoto;

    Widget child;
    String key;
    if (txt != null) {
      key = 'text';
      child = LockedTextToolbar(
        text: txt,
        onChanged: _updateTextStyle,
        onEdit: () => _editWords(txt),
      );
    } else if (img != null) {
      key = 'image';
      child = LockedImageToolbar(
        image: img,
        onReplace: _addOrReplacePhoto,
        onToggleFrame: _toggleFrame,
        onRemove: _removePhoto,
        onAdjust: img.path.isEmpty ? null : _adjustPhoto,
      );
    } else {
      key = 'idle';
      child = LockedIdleBar(
        // Only when the design takes a photo and there's no slot on the canvas
        // to tap — otherwise the canvas itself is the affordance.
        onAddPhoto:
            _t.hasPhotoOption && _photo == null ? _addOrReplacePhoto : null,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (c, anim) => FadeTransition(opacity: anim, child: c),
      child: KeyedSubtree(key: ValueKey(key), child: child),
    );
  }
}

/// Words-only editor for one locked text slot. Owns its own
/// [TextEditingController] so it's disposed exactly when the sheet goes away,
/// and previews the text in the slot's real font so the user sees the design's
/// styling while typing.
class _TextEditSheet extends StatefulWidget {
  final TextObject textObject;

  /// Field hint — set when editing the name slot so the empty field reads
  /// "Your name" / "आपका नाम".
  final String? hint;

  const _TextEditSheet({required this.textObject, this.hint});

  @override
  State<_TextEditSheet> createState() => _TextEditSheetState();
}

class _TextEditSheetState extends State<_TextEditSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.textObject.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.textObject;
    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 16.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.hint ?? S.t('edit_text'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 5,
            minLines: 1,
            textAlign: t.textAlign,
            textCapitalization: TextCapitalization.sentences,
            style: buildTextStyle(t).copyWith(
              fontSize: 20.sp,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.cardLight,
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18.sp,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 13.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(S.t('done')),
            ),
          ),
        ],
      ),
    );
  }
}
