import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/utils/canvas_image.dart';
import 'package:status_maker/features/editor/utils/image_shape_utils.dart';

/// The result of a reposition session — applied back onto the [ImageObject]
/// by the caller.
class PhotoAdjustResult {
  final Offset offset;
  final double scale;
  const PhotoAdjustResult(this.offset, this.scale);
}

const double _minPhotoScale = 1.0;
const double _maxPhotoScale = 4.0;

/// Full-screen "drag to move, pinch to zoom" adjuster for a photo inside its
/// shape (circle, heart, oval, ...). Solves the common complaint that a
/// shaped photo's auto-centred crop cuts off the part the user actually
/// wanted visible, with no way to fix it.
///
/// Lays the shape out at exactly the size [EditableImageWidget] uses on the
/// canvas (then draws it enlarged with a FittedBox), so the offset/scale
/// chosen here match the final status pixel-for-pixel — no coordinate
/// conversion needed on return.
class PhotoRepositionScreen extends StatefulWidget {
  final ImageObject image;

  const PhotoRepositionScreen({super.key, required this.image});

  @override
  State<PhotoRepositionScreen> createState() => _PhotoRepositionScreenState();
}

class _PhotoRepositionScreenState extends State<PhotoRepositionScreen> {
  late Offset _offset;
  late double _scale;
  late double _baseScale;

  @override
  void initState() {
    super.initState();
    _offset = widget.image.photoOffset;
    _scale = widget.image.photoScale.clamp(_minPhotoScale, _maxPhotoScale);
    _baseScale = _scale;
  }

  Size get _size => baseSizeForImageShape(widget.image.shape);

  /// Keeps the photo from panning far enough to reveal empty space at the
  /// shape's edges: the zoomed photo is `scale`x the box in each dimension,
  /// centred by default, so the max pan before a gap appears is half the
  /// extra size on that axis.
  Offset _clamp(Offset o, double scale, Size size) {
    final maxDx = (scale - 1) * size.width / 2;
    final maxDy = (scale - 1) * size.height / 2;
    return Offset(o.dx.clamp(-maxDx, maxDx), o.dy.clamp(-maxDy, maxDy));
  }

  void _onScaleStart(ScaleStartDetails d) {
    _baseScale = _scale;
  }

  /// [k] is how much larger than its canvas size the shape is drawn here;
  /// finger movement is divided by it so the photo tracks the finger.
  void _onScaleUpdate(ScaleUpdateDetails d, double k) {
    setState(() {
      _scale =
          (_baseScale * d.scale).clamp(_minPhotoScale, _maxPhotoScale);
      _offset = _clamp(_offset + d.focalPointDelta / k, _scale, _size);
    });
  }

  void _setZoom(double scale) {
    setState(() {
      _scale = scale;
      _baseScale = scale;
      // Zooming out shrinks how far the photo may be panned.
      _offset = _clamp(_offset, _scale, _size);
    });
  }

  void _reset() {
    setState(() {
      _offset = Offset.zero;
      _scale = _minPhotoScale;
      _baseScale = _minPhotoScale;
    });
  }

  void _done() {
    Navigator.of(context).pop(PhotoAdjustResult(_offset, _scale));
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      S.t('reposition_photo'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _done,
                    child: Text(
                      S.t('done'),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  // Show the shape as large as the screen allows — at its
                  // canvas size (~240px) it was too small to frame a face
                  // with a pinch. Everything inside is still laid out in the
                  // shape's own pixels, so the result needs no conversion;
                  // only gesture deltas are divided by [k].
                  final k = math.min(
                    box.maxWidth * 0.86 / size.width,
                    box.maxHeight * 0.86 / size.height,
                  );
                  final photo = Transform.translate(
                    offset: _offset,
                    child: Transform.scale(
                      scale: _scale,
                      child: canvasImage(
                        widget.image.path,
                        width: size.width,
                        height: size.height,
                        fit: BoxFit.cover,
                        cacheWidth: (size.width * k * _maxPhotoScale)
                            .round()
                            .clamp(1, 2400),
                      ),
                    ),
                  );
                  return GestureDetector(
                    // The whole area takes the pinch, not just the shape, so
                    // a small shape is still easy to grab with two fingers.
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: (d) => _onScaleUpdate(d, k),
                    onDoubleTap: _reset,
                    child: ClipRect(
                      child: Center(
                        child: SizedBox(
                          width: size.width * k,
                          height: size.height * k,
                          child: FittedBox(
                            child: SizedBox(
                              width: size.width,
                              height: size.height,
                              child: Stack(
                                fit: StackFit.expand,
                                clipBehavior: Clip.none,
                                children: [
                                  // The part of the photo the shape cuts
                                  // off, dimmed, so the user can see what
                                  // they could pan to.
                                  Opacity(opacity: 0.3, child: photo),
                                  clipToImageShape(widget.image.shape, photo),
                                  IgnorePointer(
                                    child: CustomPaint(
                                      painter: _ShapeOutlinePainter(
                                        widget.image.shape,
                                        strokeWidth: 2 / k,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.zoom_out, color: Colors.white70),
                  Expanded(
                    child: Slider(
                      value: _scale,
                      min: _minPhotoScale,
                      max: _maxPhotoScale,
                      activeColor: AppColors.accent,
                      inactiveColor: Colors.white24,
                      onChanged: _setZoom,
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: Colors.white70),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                S.t('reposition_hint'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, color: Colors.white70),
                label: Text(
                  S.t('reset'),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The shape's edge as a thin white line, drawn over the photo.
class _ShapeOutlinePainter extends CustomPainter {
  final ImageShape shape;
  final double strokeWidth;

  const _ShapeOutlinePainter(this.shape, {required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      imageShapePath(shape, size),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_ShapeOutlinePainter old) =>
      old.shape != shape || old.strokeWidth != strokeWidth;
}
