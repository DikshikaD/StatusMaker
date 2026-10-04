import 'package:flutter/material.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/features/editor/data/fixed_templates.dart';
import 'package:status_maker/features/editor/presentation/template_fill_screen.dart';
import 'package:status_maker/features/editor/widgets/fixed_template_canvas.dart';

/// Opens a generated template in the locked editor (words, photo, name,
/// background and language — whatever that design allows).
void openStudioTemplate(BuildContext context, FixedTemplate template) {
  Navigator.push(
    context,
    FadeSlidePageRoute(page: TemplateFillScreen(template: template)),
  );
}

/// A pixel-true, non-interactive miniature of a template — the same card the
/// Ready Templates rows use, extracted so the studio grids can share it.
class StudioTemplateCard extends StatelessWidget {
  final FixedTemplate template;
  final VoidCallback onTap;

  /// Small caption under the card (e.g. the design's name). Hidden when null.
  final String? caption;

  const StudioTemplateCard({
    super.key,
    required this.template,
    required this.onTap,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 10.r,
                offset: Offset(0, 5.h),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            // RepaintBoundary: the shader background paints once and the
            // card then scrolls as a cached layer. IgnorePointer: a preview is
            // a picture, not an editor.
            child: RepaintBoundary(
              child: IgnorePointer(
                child: FixedTemplateCanvas(
                  design: template.previewDesign(),
                  lineLimits: template.lineLimits,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (caption == null) return card;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        card,
        SizedBox(height: 6.h),
        Text(
          caption!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5.sp,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}
