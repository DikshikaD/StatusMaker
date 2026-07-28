import 'package:flutter/material.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/features/editor/data/fixed_templates.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/features/editor/widgets/fixed_template_canvas.dart';

/// The "Ready Templates" browser: a heading plus one horizontally scrolling row
/// per theme ("Good Morning", "Wishes & Festivals", …). Tapping a card opens
/// that design in the full editor as a completely editable starting point.
///
/// A widget rather than a method on one screen so it can live wherever there's
/// room for it without the rows being duplicated.
class ReadyTemplatesSection extends StatelessWidget {
  /// Height of each preview card. The width follows from the 9:16 status shape.
  final double? cardHeight;

  const ReadyTemplatesSection({super.key, this.cardHeight});

  /// The section broken into top-level pieces (heading, then one row per theme)
  /// so a host can feed them to a lazy list instead of a Column.
  ///
  /// This matters for startup cost: the tab lives in an IndexedStack, which
  /// builds every tab whether or not it's showing. Handing these to a
  /// `ListView.builder` means only the rows actually on screen get built — the
  /// widget objects here are just cheap descriptions until then. Built as a
  /// Column ([build]) all six rows mount at once, and each mounts its own
  /// visible preview canvases with it.
  List<Widget> items(BuildContext context) => [
        _heading(context),
        ..._themeSections(context),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items(context),
    );
  }

  Widget _heading(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.t('ready_templates'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 16.sp,
              ),
        ),
        SizedBox(height: 4.h),
        Text(
          S.t('ready_templates_hint'),
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5.sp,
          ),
        ),
        SizedBox(height: AppDimensions.paddingMedium),
      ],
    );
  }

  /// One labelled row per theme, in [kFixedTemplateThemes] order. Themes with no
  /// designs are skipped. Each entry is a self-contained header + row, so it can
  /// be lazily mounted on its own.
  List<Widget> _themeSections(BuildContext context) {
    final sections = <Widget>[];
    for (final theme in kFixedTemplateThemes) {
      final templates = fixedTemplatesForTheme(theme);
      if (templates.isEmpty) continue;
      sections.add(
        Padding(
          padding: EdgeInsets.only(
            top: sections.isEmpty ? 0 : AppDimensions.paddingLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    S.t('grp_$theme'),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${templates.length}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              _row(templates),
            ],
          ),
        ),
      );
    }
    return sections;
  }

  /// Horizontal strip of designs. Each card is a pixel-true, non-interactive
  /// miniature of the template it opens.
  Widget _row(List<FixedTemplate> templates) {
    final height = cardHeight ?? 232.h;
    final width = height * 9 / 16;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: templates.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final template = templates[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _open(context, template),
            child: SizedBox(
              width: width,
              height: height,
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
                  // RepaintBoundary keeps one card's paint from touching the
                  // others while the row scrolls; IgnorePointer because the
                  // preview is a picture, not an editor.
                  child: RepaintBoundary(
                    child: IgnorePointer(
                      // previewDesign() is a shared read-only snapshot, so
                      // scrolling doesn't deep-copy a design per card.
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
        },
      ),
    );
  }

  /// Opens the design in the full editor with nothing locked — it's just a
  /// starting point. `includeHiddenPhoto` brings each design's photo frame along
  /// so it's there to tap (and deletable if unwanted), and `designCanvasSize`
  /// tells the editor to map the design's 360×640 coordinates onto this
  /// device's canvas.
  void _open(BuildContext context, FixedTemplate template) {
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: StatusPersonalizerScreen(
          templateName: template.name,
          category: template.quoteCategory,
          initialDesign: template.design(includeHiddenPhoto: true),
          designCanvasSize: kFixedCanvasSize,
        ),
      ),
    );
  }
}
