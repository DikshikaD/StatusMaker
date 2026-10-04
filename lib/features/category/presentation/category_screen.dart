import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/templates_data.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/features/editor/widgets/motif_painter.dart';
import 'package:status_maker/features/editor/widgets/heart_clipper.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/features/editor/data/fixed_templates.dart';
import 'package:status_maker/studio/models/category_model.dart';
import 'package:status_maker/studio/models/language_model.dart';
import 'package:status_maker/studio/presentation/template_card.dart';
import 'package:status_maker/studio/presentation/template_language_switch.dart';
import 'package:status_maker/studio/templates/template_catalog.dart';

/// The theme names that have hand-authored designs in templates_data.dart.
/// Themes added with the studio (Success, Nature, Dark, …) have only
/// generated designs, so the legacy builder — which would fall back to its
/// generic set — is skipped for them.
const Set<String> _legacyThemes = {
  'Good Morning',
  'Morning',
  'Birthday',
  'Festival',
  'Motivation',
  'Love',
  'Business',
  'Devotional',
  'Suprabhat',
  'Good Night',
  'Suvichar',
};

/// One theme's designs, in a single grid: the generated studio templates for
/// the matching category first (locked editor, with quote / photo / name /
/// background / language options), then the hand-authored designs that open
/// in the free editor. Both kinds are 9:16 cards, so they share one grid.
class CategoryScreen extends StatefulWidget {
  final String categoryName;

  const CategoryScreen({super.key, required this.categoryName});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  /// Language the generated designs carry — starts as the app language.
  AppLanguage _lang = AppLanguage.current;

  String get _name => widget.categoryName;

  @override
  Widget build(BuildContext context) {
    final studioId = studioCategoryForTheme(_name);
    final generated = studioId == null
        ? const <FixedTemplate>[]
        : TemplateCatalog.templatesFor(studioId, language: _lang);
    final legacy = _legacyThemes.contains(_name)
        ? templatesForCategory(_name)
        : const <StatusTemplate>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${S.cat(_name)} ${S.t('category_templates')}',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (generated.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: TemplateLanguageSwitch(
                value: _lang,
                onChanged: (l) => setState(() => _lang = l),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppDimensions.paddingLarge, 4.h, AppDimensions.paddingLarge, 12.h),
            child: Text(
              S.t('tap_design_hint'),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
            ),
          ),
          Expanded(
            child: GridView.builder(
              // Keyed on the language so switching rebuilds the generated
              // cards instead of morphing one language's canvases into the
              // other's.
              key: ValueKey(_lang.code),
              padding: EdgeInsets.fromLTRB(
                  AppDimensions.paddingLarge, 0, AppDimensions.paddingLarge, AppDimensions.paddingLarge),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
              ),
              itemCount: generated.length + legacy.length,
              // Each tile draws a gradient / shader background + styled text;
              // a RepaintBoundary keeps one tile's paint from touching others
              // while the grid scrolls.
              itemBuilder: (context, index) {
                if (index < generated.length) {
                  final t = generated[index];
                  return StudioTemplateCard(
                    template: t,
                    onTap: () => openStudioTemplate(context, t),
                  );
                }
                return RepaintBoundary(
                  child: TemplateCard(
                      template: legacy[index - generated.length],
                      category: _name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TemplateCard extends StatelessWidget {
  final StatusTemplate template;
  final String category;

  const TemplateCard({required this.template, required this.category});

  Alignment _alignment() {
    final v = template.anchor == TemplateAnchor.top
        ? -1.0
        : template.anchor == TemplateAnchor.bottom
            ? 1.0
            : 0.0;
    final h = template.align == TextAlign.left
        ? -1.0
        : template.align == TextAlign.right
            ? 1.0
            : 0.0;
    return Alignment(h, v);
  }

  Widget _imageFrame() {
    Widget box = Container(
      width: 78.w,
      height: template.imageShape == ImageShape.roundedRectangle ? 92.h : 78.h,
      color: Colors.white.withValues(alpha: 0.30),
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: Colors.white, size: 24.w),
    );
    switch (template.imageShape) {
      case ImageShape.circle:
      case ImageShape.oval:
        box = ClipOval(child: box);
        break;
      case ImageShape.roundedRectangle:
        box = ClipRRect(borderRadius: BorderRadius.circular(14.r), child: box);
        break;
      case ImageShape.heart:
        box = ClipPath(clipper: HeartClipper(), child: box);
        break;
      case ImageShape.square:
      case null:
        break;
    }
    return box;
  }

  Widget _highlightWrap(Widget child) {
    if (template.highlight == null) return child;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: template.highlight,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          FadeSlidePageRoute(
            page: StatusPersonalizerScreen(
              templateName: category,
              category: category,
              template: template,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            colors: template.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Stack(
          children: [
            // Decorative motif — part of the finished design.
            Positioned.fill(
              child: CustomPaint(
                painter: MotifPainter(template.motif, template.textColor),
              ),
            ),
            // Shaped photo frame (if this template includes an image).
            if (template.hasImage)
              Positioned.fill(
                child: Align(
                  alignment: template.imagePosition.dy < 150
                      ? const Alignment(0, -0.62)
                      : const Alignment(0, 0.62),
                  child: _imageFrame(),
                ),
              ),
            // The designed quote — the actual composition you'll get.
            Positioned.fill(
              child: Align(
                alignment: _alignment(),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: _highlightWrap(
                    Text(
                      template.text,
                      textAlign: template.align,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.getFont(
                        template.fontFamily,
                        color: template.textColor,
                        fontWeight:
                            template.bold ? FontWeight.w700 : FontWeight.w400,
                        fontSize: (template.fontSize * 0.46).clamp(12.0, 22.0),
                        letterSpacing: template.letterSpacing * 0.5,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Small "use" affordance
            Positioned(
              top: 10.h,
              right: 10.w,
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit, color: Colors.white, size: 15.w),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
