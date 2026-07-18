import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/utils/editor_export.dart';
import 'package:status_maker/features/editor/widgets/status_canvas.dart';
import 'package:status_maker/features/editor/widgets/toolbars/add_bar.dart';
import 'package:status_maker/features/editor/widgets/toolbars/text_toolbar.dart';
import 'package:status_maker/features/editor/widgets/toolbars/image_toolbar.dart';
import 'package:status_maker/features/editor/widgets/bottom_sheets/background_sheet.dart';
import 'package:status_maker/features/editor/widgets/bottom_sheets/quotes_sheet.dart';

class StatusPersonalizerScreen extends StatefulWidget {
  final String templateName;
  final String category;

  const StatusPersonalizerScreen({
    super.key,
    this.templateName = 'Status',
    this.category = '',
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
      _controller.setBackground(const BackgroundState(
        gradientColors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      ));
      _controller.addText('Double tap to edit');
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

  void _addText() => _controller.addText('Double tap to edit');

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
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      // Keep the canvas at full size when the keyboard opens for editing —
      // otherwise the whole editor shrinks/squeezes.
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
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
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          _pill(
            label: 'Save',
            icon: Icons.download_rounded,
            filled: false,
            onTap: () => _export(share: false),
          ),
          const SizedBox(width: 10),
          _pill(
            label: 'Share',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
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
          );
        } else {
          key = 'add';
          child = AddBar(
            onBackground: _showBackgroundSheet,
            onPhoto: _pickImage,
            onText: _addText,
            onQuotes: _showQuotesSheet,
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
