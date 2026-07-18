import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/utils/text_style_builder.dart';

enum _Panel { none, font, size, color, align, letter, line }

const List<Color> _kTextColors = [
  Colors.white,
  Colors.black,
  Color(0xFFE38870), // brand accent
  Color(0xFFFFD54F),
  Color(0xFFEF5350),
  Color(0xFF66BB6A),
  Color(0xFF42A5F5),
  Color(0xFFAB47BC),
  Color(0xFFFF7043),
  Color(0xFF26C6DA),
];

/// Contextual toolbar for the selected text. One icon row + one inline panel
/// that opens directly above it — every control uses the same pattern, so
/// there's exactly one thing to learn.
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
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
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
          label: 'Size',
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
          label: 'Letter spacing',
          onChanged: (v) => widget.onChanged(_t.copyWith(letterSpacing: v)),
        );
      case _Panel.line:
        return _slider(
          value: _t.lineHeight,
          min: 1.0,
          max: 2.5,
          label: 'Line spacing',
          onChanged: (v) => widget.onChanged(_t.copyWith(lineHeight: v)),
        );
      case _Panel.none:
        return const SizedBox.shrink();
    }
  }

  Widget _fontPanel() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kEditorFonts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final font = kEditorFonts[i];
          final selected = font == _t.fontFamily;
          return GestureDetector(
            onTap: () => widget.onChanged(_t.copyWith(fontFamily: font)),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                font,
                style: GoogleFonts.getFont(
                  font,
                  color: Colors.white,
                  fontSize: 16,
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
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kTextColors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final color = _kTextColors[i];
          final selected = color == _t.color;
          return GestureDetector(
            onTap: () => widget.onChanged(_t.copyWith(color: color)),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.accent : Colors.white24,
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
          width: 48,
          height: 40,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        btn(TextAlign.left, Icons.format_align_left),
        const SizedBox(width: 12),
        btn(TextAlign.center, Icons.format_align_center),
        const SizedBox(width: 12),
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
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
                color: AppColors.darkTextSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              thumbColor: AppColors.accent,
              inactiveTrackColor: Colors.white24,
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

  Widget _iconRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _tool(
            label: 'Font',
            active: _active == _Panel.font,
            onTap: () => _toggle(_Panel.font),
            child: const Text('Aa',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ),
          _iconTool(Icons.format_size, 'Size', _active == _Panel.size,
              () => _toggle(_Panel.size)),
          _tool(
            label: 'Color',
            active: _active == _Panel.color,
            onTap: () => _toggle(_Panel.color),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _t.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54),
              ),
            ),
          ),
          _tool(
            label: 'Bold',
            active: _t.bold,
            onTap: () => widget.onChanged(_t.copyWith(bold: !_t.bold)),
            child: const Text('B',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ),
          _tool(
            label: 'Italic',
            active: _t.italic,
            onTap: () => widget.onChanged(_t.copyWith(italic: !_t.italic)),
            child: const Text('I',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700)),
          ),
          _iconTool(Icons.format_align_center, 'Align', _active == _Panel.align,
              () => _toggle(_Panel.align)),
          _iconTool(Icons.swap_horiz, 'Letter', _active == _Panel.letter,
              () => _toggle(_Panel.letter)),
          _iconTool(Icons.format_line_spacing, 'Line', _active == _Panel.line,
              () => _toggle(_Panel.line)),
        ],
      ),
    );
  }

  Widget _iconTool(IconData icon, String label, bool active, VoidCallback onTap) {
    return _tool(
      label: label,
      active: active,
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _tool({
    required String label,
    required bool active,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accent.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: child,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.darkTextSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
