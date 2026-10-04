import 'package:flutter/material.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/template_motif.dart';
import 'package:status_maker/features/editor/widgets/motif_painter.dart';
import 'package:status_maker/studio/renderers/background_thumbnail_cache.dart';

/// One picker tile for a generated background: the cached bitmap plus the
/// preset's motif drawn over it, so the tile shows what the canvas will.
class StudioBackgroundTile extends StatelessWidget {
  final BackgroundState state;
  final VoidCallback onTap;
  final bool selected;

  const StudioBackgroundTile({
    super.key,
    required this.state,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = state.generated;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cfg != null)
                BackgroundThumb(config: cfg, width: 144, height: 256)
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: state.color,
                    gradient: state.isGradient
                        ? LinearGradient(colors: state.gradientColors!)
                        : null,
                  ),
                ),
              if (state.motif != TemplateMotif.none)
                IgnorePointer(
                  child: CustomPaint(
                    painter: MotifPainter(
                      state.motif,
                      state.motifColor ?? Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing the backgrounds a locked template may switch to.
class StudioBackgroundSheet extends StatelessWidget {
  final List<BackgroundState> backgrounds;
  final BackgroundState current;
  final ValueChanged<BackgroundState> onSelect;

  const StudioBackgroundSheet({
    super.key,
    required this.backgrounds,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.7;
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
            SizedBox(height: 14.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                S.t('pick_background'),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  childAspectRatio: 0.6,
                ),
                itemCount: backgrounds.length,
                itemBuilder: (_, i) {
                  final bg = backgrounds[i];
                  return StudioBackgroundTile(
                    state: bg,
                    selected: bg.generated != null &&
                        bg.generated == current.generated,
                    onTap: () {
                      onSelect(bg);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
