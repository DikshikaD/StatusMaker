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
/// Renders the shape at exactly the same size [EditableImageWidget] uses on
/// the canvas, so the offset/scale chosen here match the final status
/// pixel-for-pixel — no coordinate conversion needed on return.
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

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      _scale =
          (_baseScale * d.scale).clamp(_minPhotoScale, _maxPhotoScale);
      _offset = _clamp(_offset + d.focalPointDelta, _scale, _size);
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
              child: Center(
                child: GestureDetector(
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        clipToImageShape(
                          widget.image.shape,
                          Transform.translate(
                            offset: _offset,
                            child: Transform.scale(
                              scale: _scale,
                              child: canvasImage(
                                widget.image.path,
                                width: size.width,
                                height: size.height,
                                fit: BoxFit.cover,
                                cacheWidth: (size.width * 2 * _maxPhotoScale)
                                    .round()
                                    .clamp(1, 2400),
                              ),
                            ),
                          ),
                        ),
                        // A visual guide for the shape's edge — purely
                        // decorative, doesn't affect the crop.
                        IgnorePointer(
                          child: clipToImageShape(
                            widget.image.shape,
                            DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
