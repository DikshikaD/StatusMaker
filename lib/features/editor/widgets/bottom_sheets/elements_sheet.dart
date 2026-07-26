import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/asset_backgrounds.dart';
import 'package:status_maker/features/editor/widgets/element_painter.dart';
import 'package:status_maker/features/editor/widgets/frame_painter.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// Picker for decorative vector elements (stickers) and full-status frames.
/// Two tabs share a colour row so the user picks the colour before adding.
class ElementsSheet extends StatefulWidget {
  /// [assetPath] is set only when the user picked an illustrated sticker
  /// image (see [ElementShape.imageSticker]) — null for every drawn shape.
  final void Function(ElementShape shape, Color color, String? assetPath)
      onAddElement;
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
  int _tab = 0; // 0 = shapes, 1 = stickers, 2 = frames
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

  // Plain single-tone icons (recolour fully to whatever's picked above).
  static const List<ElementShape> _shapes = [
    ElementShape.heart,
    ElementShape.star,
    ElementShape.circle,
    ElementShape.ring,
    ElementShape.sparkle,
    ElementShape.flower,
    ElementShape.diamond,
    ElementShape.triangle,
    ElementShape.line,
    ElementShape.arrow,
    ElementShape.balloon,
    ElementShape.gift,
    ElementShape.crown,
    ElementShape.moon,
    ElementShape.cloud,
    ElementShape.bolt,
    ElementShape.leaf,
    ElementShape.musicNote,
    ElementShape.ribbon,
    ElementShape.confetti,
  ];

  // Expressive character stickers — only the body colour follows the palette;
  // faces keep their own fixed, cute colouring (see ElementPainter).
  static const List<ElementShape> _stickers = [
    ElementShape.happySun,
    ElementShape.winkStar,
    ElementShape.blushHeart,
    ElementShape.sleepyMoon,
    ElementShape.waveHand,
    ElementShape.partyPopper,
    ElementShape.catFace,
    ElementShape.heartEyesFace,
  ];

  static const List<StatusFrame> _frames = StatusFrame.values;

  // Illustrated sticker image paths under assets/stickers/, discovered at
  // runtime (see stickerAssets()) so dropping a new image in that folder
  // shows up here with no code change.
  List<String> _imageStickers = [];

  @override
  void initState() {
    super.initState();
    _loadImageStickers();
  }

  Future<void> _loadImageStickers() async {
    final paths = await stickerAssets();
    if (mounted) setState(() => _imageStickers = paths);
  }

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
                child: switch (_tab) {
                  0 => _shapesGrid(_shapes),
                  1 => _stickersTab(),
                  _ => _framesTab(),
                },
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
      child: Row(children: [
        tab(S.t('shapes'), 0),
        tab(S.t('stickers'), 1),
        tab(S.t('frames'), 2),
      ]),
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

  Widget _shapesGrid(List<ElementShape> shapes) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      children: [
        for (final s in shapes)
          GestureDetector(
            onTap: () {
              widget.onAddElement(s, _color, null);
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

  /// Stickers tab: illustrated PNG stickers first (the real "WhatsApp-style"
  /// ones), then the drawn character stickers below — both go on the canvas
  /// the same way, just rendered differently.
  Widget _stickersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_imageStickers.isNotEmpty) ...[
          _imageStickersGrid(),
          SizedBox(height: 18.h),
          Text(
            S.t('drawn_stickers'),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
        ],
        _shapesGrid(_stickers),
      ],
    );
  }

  Widget _imageStickersGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      children: [
        for (final path in _imageStickers)
          GestureDetector(
            onTap: () {
              widget.onAddElement(ElementShape.imageSticker, _color, path);
              Navigator.of(context).pop();
            },
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Image.asset(
                path,
                fit: BoxFit.contain,
                cacheWidth: 160,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textSecondary,
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
