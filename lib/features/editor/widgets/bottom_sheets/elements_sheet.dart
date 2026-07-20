import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/widgets/element_painter.dart';
import 'package:status_maker/features/editor/widgets/frame_painter.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// Picker for decorative vector elements (stickers) and full-status frames.
/// Two tabs share a colour row so the user picks the colour before adding.
class ElementsSheet extends StatefulWidget {
  final void Function(ElementShape shape, Color color) onAddElement;
  final void Function(StatusFrame frame, Color color, double width) onSetFrame;
  final ValueChanged<double> onFrameWidth;
  final StatusFrame currentFrame;
  final double currentFrameWidth;

  const ElementsSheet({
    super.key,
    required this.onAddElement,
    required this.onSetFrame,
    required this.onFrameWidth,
    this.currentFrame = StatusFrame.none,
    this.currentFrameWidth = 1.0,
  });

  @override
  State<ElementsSheet> createState() => _ElementsSheetState();
}

class _ElementsSheetState extends State<ElementsSheet> {
  int _tab = 0; // 0 = shapes, 1 = frames
  Color _color = Colors.white;
  late double _frameWidth = widget.currentFrameWidth;

  static const List<Color> _palette = [
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

  static const List<ElementShape> _shapes = ElementShape.values;

  static const List<StatusFrame> _frames = StatusFrame.values;

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.78;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),
            _segment(),
            SizedBox(height: 14.h),
            _colorRow(),
            SizedBox(height: 14.h),
            Flexible(
              child: SingleChildScrollView(
                child: _tab == 0 ? _shapesGrid() : _framesTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment() {
    Widget tab(String label, int index) {
      final selected = _tab == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(children: [tab(S.t('shapes'), 0), tab(S.t('frames'), 1)]),
    );
  }

  Widget _colorRow() {
    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _palette.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (_, i) {
          final c = _palette[i];
          final selected = c == _color;
          return GestureDetector(
            onTap: () => setState(() => _color = c),
            child: Container(
              width: 34.w,
              height: 34.h,
              decoration: BoxDecoration(
                color: c,
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

  Widget _shapesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      children: [
        for (final s in _shapes)
          GestureDetector(
            onTap: () {
              widget.onAddElement(s, _color);
              Navigator.of(context).pop();
            },
            child: Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.border),
              ),
              child: CustomPaint(
                painter: ElementPainter(
                  shape: s,
                  color: _color == Colors.white
                      ? AppColors.textPrimary
                      : _color,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _framesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.line_weight,
                color: AppColors.textSecondary, size: 20.w),
            SizedBox(width: 6.w),
            Text(S.t('width'),
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12.sp)),
            Expanded(
              child: Slider(
                value: _frameWidth.clamp(0.4, 3.0),
                min: 0.4,
                max: 3.0,
                activeColor: AppColors.accent,
                onChanged: (v) {
                  setState(() => _frameWidth = v);
                  // Live-update the canvas if a frame is already applied.
                  widget.onFrameWidth(v);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        _framesGrid(),
      ],
    );
  }

  Widget _framesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 0.7,
      children: [
        for (final f in _frames)
          GestureDetector(
            onTap: () {
              widget.onSetFrame(f, _color, _frameWidth);
              Navigator.of(context).pop();
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: widget.currentFrame == f
                      ? AppColors.accent
                      : AppColors.border,
                  width: widget.currentFrame == f ? 2 : 1,
                ),
              ),
              child: f == StatusFrame.none
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block, color: AppColors.textSecondary, size: 22.w),
                        SizedBox(height: 4.h),
                        Text(S.t('none'),
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 11.sp)),
                      ],
                    )
                  : CustomPaint(
                      painter: FramePainter(
                        frame: f,
                        color: _color == Colors.white
                            ? AppColors.textPrimary
                            : _color,
                        width: _frameWidth,
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}
