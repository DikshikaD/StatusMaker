import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/utils/text_style_builder.dart';
import 'package:status_maker/features/editor/widgets/bottom_sheets/font_sheet.dart';
import 'package:status_maker/core/utils/responsive.dart';

enum _Panel { none, font, size, color, align, letter, line }

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
];

/// Contextual toolbar for the selected text. Light theme to match the app.
class TextToolbar extends StatefulWidget {
  final TextObject text;
  final ValueChanged<TextObject> onChanged;

  const TextToolbar({super.key, required this.text, required this.onChanged});

  @override
  State<TextToolbar> createState() => _TextToolbarState();
}

class _TextToolbarState extends State<TextToolbar> {
  _Panel _active = _Panel.none;

  void _toggle(_Panel p) =>
      setState(() => _active = _active == p ? _Panel.none : p);

  TextObject get _t => widget.text;

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
              child: _active == _Panel.none
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 4.h),
                      child: _panel(),
                    ),
            ),
            _iconRow(),
          ],
        ),
      ),
    );
  }

  Widget _panel() {
    switch (_active) {
      case _Panel.font:
        return _fontPanel();
      case _Panel.size:
        return _slider(
          value: _t.fontSize,
          min: 12,
          max: 96,
          label: S.t('size'),
          onChanged: (v) => widget.onChanged(_t.copyWith(fontSize: v)),
        );
      case _Panel.color:
        return _colorPanel();
      case _Panel.align:
        return _alignPanel();
      case _Panel.letter:
        return _slider(
          value: _t.letterSpacing,
          min: -2,
          max: 12,
          label: S.t('letter_spacing'),
          onChanged: (v) => widget.onChanged(_t.copyWith(letterSpacing: v)),
        );
      case _Panel.line:
        return _slider(
          value: _t.lineHeight,
          min: 1.0,
          max: 2.5,
          label: S.t('line_spacing'),
          onChanged: (v) => widget.onChanged(_t.copyWith(lineHeight: v)),
        );
      case _Panel.none:
        return const SizedBox.shrink();
    }
  }

  Widget _fontPanel() {
    return SizedBox(
      height: 48.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kEditorFonts.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final font = kEditorFonts[i];
          final selected = font == _t.fontFamily;
          return GestureDetector(
            onTap: () => widget.onChanged(_t.copyWith(fontFamily: font)),
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.cardLight,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                font,
                style: GoogleFonts.getFont(
                  font,
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 16.sp,
                ),
              ),
            ),
          );
        },
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

  Widget _alignPanel() {
    Widget btn(TextAlign a, IconData icon) {
      final selected = _t.textAlign == a;
      return GestureDetector(
        onTap: () => widget.onChanged(_t.copyWith(textAlign: a)),
        child: Container(
          width: 48.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.cardLight,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon,
              color: selected ? Colors.white : AppColors.textPrimary, size: 20.w),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        btn(TextAlign.left, Icons.format_align_left),
        SizedBox(width: 12.w),
        btn(TextAlign.center, Icons.format_align_center),
        SizedBox(width: 12.w),
        btn(TextAlign.right, Icons.format_align_right),
      ],
    );
  }

  Widget _slider({
    required double value,
    required double min,
    required double max,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 116.w,
          child: Text(
            label,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13.sp),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              thumbColor: AppColors.accent,
              inactiveTrackColor: AppColors.border,
              overlayColor: AppColors.accent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  /// Opens the full-screen-style font picker: a 3-column grid where every
  /// tile previews the app name in that font, so styles are easy to compare.
  void _openFontSheet() {
    setState(() => _active = _Panel.none);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FontSheet(
        currentFont: _t.fontFamily,
        onSelect: (font) => widget.onChanged(_t.copyWith(fontFamily: font)),
      ),
    );
  }

  Widget _iconRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          _tool(
            label: S.t('font'),
            active: _active == _Panel.font,
            onTap: _openFontSheet,
            childBuilder: (c) => Text('Aa',
                style: TextStyle(
                    color: c, fontSize: 18.sp, fontWeight: FontWeight.w700)),
          ),
          _iconTool(Icons.format_size, S.t('size'), _active == _Panel.size,
              () => _toggle(_Panel.size)),
          _tool(
            label: S.t('color'),
            active: _active == _Panel.color,
            onTap: () => _toggle(_Panel.color),
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
          _tool(
            label: S.t('bold'),
            active: _t.bold,
            onTap: () => widget.onChanged(_t.copyWith(bold: !_t.bold)),
            childBuilder: (c) => Text('B',
                style: TextStyle(
                    color: c, fontSize: 18.sp, fontWeight: FontWeight.w800)),
          ),
          _tool(
            label: S.t('italic'),
            active: _t.italic,
            onTap: () => widget.onChanged(_t.copyWith(italic: !_t.italic)),
            childBuilder: (c) => Text('I',
                style: TextStyle(
                    color: c,
                    fontSize: 18.sp,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700)),
          ),
          _iconTool(Icons.format_align_center, S.t('align'),
              _active == _Panel.align, () => _toggle(_Panel.align)),
          _iconTool(Icons.swap_horiz, S.t('letter'), _active == _Panel.letter,
              () => _toggle(_Panel.letter)),
          _iconTool(Icons.format_line_spacing, S.t('line'),
              _active == _Panel.line, () => _toggle(_Panel.line)),
        ],
      ),
    );
  }

  Widget _iconTool(IconData icon, String label, bool active, VoidCallback onTap) {
    return _tool(
      label: label,
      active: active,
      onTap: onTap,
      childBuilder: (c) => Icon(icon, color: c, size: 20.w),
    );
  }

  Widget _tool({
    required String label,
    required bool active,
    required VoidCallback onTap,
    required Widget Function(Color contentColor) childBuilder,
  }) {
    final content = active ? Colors.white : AppColors.textPrimary;
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
                color: active ? AppColors.accent : AppColors.cardLight,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: childBuilder(content),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 11.sp),
            ),
          ],
        ),
      ),
    );
  }
}
