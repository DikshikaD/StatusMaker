import 'package:flutter/material.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/utils/sheet_coordinator.dart';
import 'package:status_maker/features/editor/widgets/bottom_sheets/font_sheet.dart';

/// Toolbars for the LOCKED template editor. They deliberately expose only the
/// controls that cannot change a design's composition:
///
///  • text — the words, font, colour, bold, italic. NOT size, alignment or
///    letter/line spacing: every slot sits at a fixed position with a fixed
///    line allowance, and those four are the only properties that would change
///    how much room the text needs and so push the design out of shape.
///  • photo — which picture, how it's cropped inside its frame, and the frame
///    border. NOT the shape, which would resize the slot's box.
///
/// Styling mirrors the free editor's toolbars so the two feel like one app.

/// Shared chrome: rounded surface panel that the toolbars sit in.
class _ToolbarShell extends StatelessWidget {
  final Widget? panel;
  final Widget row;

  const _ToolbarShell({this.panel, required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: panel == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 4.h),
                      child: panel,
                    ),
            ),
            row,
          ],
        ),
      ),
    );
  }
}

/// One labelled tool button, matching the free editor's toolbar buttons.
class _Tool extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Widget Function(Color contentColor) childBuilder;
  final Color? tint;

  const _Tool({
    required this.label,
    required this.active,
    required this.onTap,
    required this.childBuilder,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final content = active ? Colors.white : (tint ?? AppColors.textPrimary);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46.w,
              height: 46.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accent
                    : (tint != null
                        ? tint!.withValues(alpha: 0.12)
                        : AppColors.cardLight),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: childBuilder(content),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp),
            ),
          ],
        ),
      ),
    );
  }
}

const List<Color> _kTextColors = [
  Colors.white,
  Colors.black,
  Color(0xFFE38870),
  Color(0xFFFFD54F),
  Color(0xFFEF5350),
  Color(0xFF66BB6A),
  Color(0xFF42A5F5),
  Color(0xFFAB47BC),
  Color(0xFFFF7043),
  Color(0xFF26C6DA),
  Color(0xFFE8C56E),
  Color(0xFF7B1113),
];

/// Contextual toolbar for a selected text slot in a locked design.
class LockedTextToolbar extends StatefulWidget {
  final TextObject text;
  final ValueChanged<TextObject> onChanged;

  /// Opens the words editor for this slot.
  final VoidCallback onEdit;

  const LockedTextToolbar({
    super.key,
    required this.text,
    required this.onChanged,
    required this.onEdit,
  });

  @override
  State<LockedTextToolbar> createState() => _LockedTextToolbarState();
}

class _LockedTextToolbarState extends State<LockedTextToolbar> {
  bool _showColors = false;

  TextObject get _t => widget.text;

  void _openFontSheet() {
    setState(() => _showColors = false);
    SheetCoordinator.show(
      context,
      builder: (_) => FontSheet(
        currentFont: _t.fontFamily,
        onSelect: (font) => widget.onChanged(_t.copyWith(fontFamily: font)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ToolbarShell(
      panel: _showColors ? _colorPanel() : null,
      row: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            _Tool(
              label: S.t('edit_text'),
              active: false,
              onTap: widget.onEdit,
              childBuilder: (c) => Icon(Icons.keyboard, color: c, size: 20.w),
            ),
            _Tool(
              label: S.t('font'),
              active: false,
              onTap: _openFontSheet,
              childBuilder: (c) => Text(
                'Aa',
                style: TextStyle(
                    color: c, fontSize: 18.sp, fontWeight: FontWeight.w700),
              ),
            ),
            _Tool(
              label: S.t('color'),
              active: _showColors,
              onTap: () => setState(() => _showColors = !_showColors),
              childBuilder: (_) => Container(
                width: 22.w,
                height: 22.h,
                decoration: BoxDecoration(
                  color: _t.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
              ),
            ),
            _Tool(
              label: S.t('bold'),
              active: _t.bold,
              onTap: () => widget.onChanged(_t.copyWith(bold: !_t.bold)),
              childBuilder: (c) => Text(
                'B',
                style: TextStyle(
                    color: c, fontSize: 18.sp, fontWeight: FontWeight.w800),
              ),
            ),
            _Tool(
              label: S.t('italic'),
              active: _t.italic,
              onTap: () => widget.onChanged(_t.copyWith(italic: !_t.italic)),
              childBuilder: (c) => Text(
                'I',
                style: TextStyle(
                  color: c,
                  fontSize: 18.sp,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorPanel() {
    return SizedBox(
      height: 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kTextColors.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (_, i) {
          final color = _kTextColors[i];
          final selected = color == _t.color;
          return GestureDetector(
            onTap: () => widget.onChanged(_t.copyWith(color: color)),
            child: Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.border,
                  width: selected ? 3 : 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Contextual toolbar for the photo slot in a locked design.
class LockedImageToolbar extends StatelessWidget {
  final ImageObject image;
  final VoidCallback onReplace;
  final VoidCallback onToggleFrame;
  final VoidCallback onRemove;

  /// Pan/zoom the picture inside its fixed frame. Null while the slot is still
  /// empty — there's nothing to crop yet.
  final VoidCallback? onAdjust;

  const LockedImageToolbar({
    super.key,
    required this.image,
    required this.onReplace,
    required this.onToggleFrame,
    required this.onRemove,
    this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final empty = image.isPlaceholder || image.path.isEmpty;
    return _ToolbarShell(
      row: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            _Tool(
              label: empty ? S.t('add_photo') : S.t('replace'),
              active: false,
              onTap: onReplace,
              childBuilder: (c) => Icon(
                Icons.add_photo_alternate_outlined,
                color: c,
                size: 22.w,
              ),
            ),
            if (onAdjust != null)
              _Tool(
                label: S.t('adjust'),
                active: false,
                onTap: onAdjust!,
                childBuilder: (c) =>
                    Icon(Icons.crop_free, color: c, size: 22.w),
              ),
            _Tool(
              label: S.t('frame'),
              active: image.framed,
              onTap: onToggleFrame,
              childBuilder: (c) =>
                  Icon(Icons.border_style, color: c, size: 22.w),
            ),
            if (!empty)
              _Tool(
                label: S.t('remove_photo'),
                active: false,
                tint: Colors.redAccent,
                onTap: onRemove,
                childBuilder: (c) =>
                    Icon(Icons.delete_outline, color: c, size: 22.w),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shown when nothing is selected: a hint about what's tappable, plus the one
/// action that has nowhere else to live — adding a photo to a design whose
/// slot isn't on the canvas yet. Without this, removing the photo from such a
/// design would leave no way to put one back.
class LockedIdleBar extends StatelessWidget {
  /// Non-null only when this design takes a photo and none is placed, so there
  /// is nothing on the canvas to tap.
  final VoidCallback? onAddPhoto;

  // Studio templates expose a few whole-design options that have no object
  // on the canvas to tap. Each is shown only when non-null, so the
  // hand-authored designs — which pass none of them — look exactly as before.

  /// Pick a different ready-made quote for the design's quote slot.
  final VoidCallback? onQuotes;

  /// Swap in another of the design's alternate backgrounds.
  final VoidCallback? onBackground;

  /// Switch the design's wording to the other language.
  final VoidCallback? onLanguage;

  /// Label for [onLanguage] — the language it switches *to*.
  final String? languageLabel;

  /// Fill the (currently empty, and therefore invisible) name slot.
  final VoidCallback? onAddName;

  const LockedIdleBar({
    super.key,
    this.onAddPhoto,
    this.onQuotes,
    this.onBackground,
    this.onLanguage,
    this.languageLabel,
    this.onAddName,
  });

  bool get _hasTools =>
      onAddPhoto != null ||
      onQuotes != null ||
      onBackground != null ||
      onLanguage != null ||
      onAddName != null;

  @override
  Widget build(BuildContext context) {
    return _ToolbarShell(
      row: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_outlined,
                    size: 16.w, color: AppColors.textSecondary),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    S.t('locked_select_hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5.sp,
                    ),
                  ),
                ),
              ],
            ),
            if (_hasTools) ...[
              SizedBox(height: 6.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onQuotes != null)
                      _Tool(
                        label: S.t('change_quote'),
                        active: false,
                        onTap: onQuotes!,
                        childBuilder: (c) => Icon(Icons.format_quote_rounded,
                            color: c, size: 22.w),
                      ),
                    if (onAddPhoto != null)
                      _Tool(
                        label: S.t('add_photo'),
                        active: false,
                        onTap: onAddPhoto!,
                        childBuilder: (c) => Icon(
                          Icons.add_photo_alternate_outlined,
                          color: c,
                          size: 22.w,
                        ),
                      ),
                    if (onAddName != null)
                      _Tool(
                        label: S.t('add_name'),
                        active: false,
                        onTap: onAddName!,
                        childBuilder: (c) =>
                            Icon(Icons.badge_outlined, color: c, size: 22.w),
                      ),
                    if (onBackground != null)
                      _Tool(
                        label: S.t('background'),
                        active: false,
                        onTap: onBackground!,
                        childBuilder: (c) => Icon(Icons.wallpaper_rounded,
                            color: c, size: 22.w),
                      ),
                    if (onLanguage != null)
                      _Tool(
                        label: languageLabel ?? S.t('language'),
                        active: false,
                        onTap: onLanguage!,
                        childBuilder: (c) =>
                            Icon(Icons.translate_rounded, color: c, size: 22.w),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
