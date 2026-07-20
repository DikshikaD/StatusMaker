import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/templates_data.dart';
import 'package:status_maker/features/editor/utils/editor_export.dart';
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

  const StatusPersonalizerScreen({
    super.key,
    this.templateName = 'Status',
    this.category = '',
    this.template,
  });

  @override
  State<StatusPersonalizerScreen> createState() =>
      _StatusPersonalizerScreenState();
}

class _StatusPersonalizerScreenState extends State<StatusPersonalizerScreen> {
  late final EditorController _controller;
  final GlobalKey _canvasKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _controller = EditorController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final t = widget.template;
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
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---- actions --------------------------------------------------------------
  Future<void> _pickImage() async {
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x != null) _controller.addImage(x.path);
  }

  void _addText() {
    // Add an empty text and drop straight into the keyboard — no placeholder.
    final obj = _controller.addText('');
    _controller.requestEdit(obj.id);
  }

  Future<void> _replaceImage(String id) async {
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x != null) _controller.fillImage(id, x.path);
  }

  void _showElementsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ElementsSheet(
        currentFrame: _controller.frame,
        currentFrameWidth: _controller.frameWidth,
        onAddElement: (shape, color) =>
            _controller.addElement(shape, color: color),
        onSetFrame: (frame, color, width) =>
            _controller.setFrame(frame, color: color, width: width),
        onFrameWidth: _controller.setFrameWidth,
      ),
    );
  }

  void _showQuotesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuotesSheet(
        category: widget.category,
        onSelect: (quote) => _controller.addText(quote),
      ),
    );
  }

  void _showBackgroundSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BackgroundSheet(
        onSelect: _controller.setBackground,
        onPickGallery: () async {
          Navigator.of(context).pop();
          final x = await _picker.pickImage(
              source: ImageSource.gallery, imageQuality: 90);
          if (x != null) {
            _controller.setBackground(BackgroundState(imagePath: x.path));
          }
        },
      ),
    );
  }

  Future<void> _export({required bool share}) async {
    if (_exporting) return;
    _exporting = true;
    _controller.clearSelection();
    await WidgetsBinding.instance.endOfFrame;
    try {
      final bytes = await captureCanvas(_canvasKey);
      if (bytes == null) return;
      if (share) {
        await shareBytes(bytes);
      } else {
        final path = await saveToFile(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to $path')),
          );
        }
      }
    } finally {
      _exporting = false;
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
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          _pill(
            label: S.t('save'),
            icon: Icons.download_rounded,
            filled: false,
            onTap: () => _export(share: false),
          ),
          SizedBox(width: 10.w),
          _pill(
            label: S.t('share'),
            icon: Icons.ios_share,
            filled: true,
            onTap: () => _export(share: true),
          ),

        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : AppColors.cardLight,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18.w,
                color: filled ? Colors.white : AppColors.textPrimary),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                  color: filled ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp),
            ),
          ],
        ),
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
