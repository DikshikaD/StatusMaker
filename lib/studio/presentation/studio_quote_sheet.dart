import 'package:flutter/material.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// Tap-to-pick list of quotes for a locked template's quote slot. Plain
/// strings in: the caller has already chosen category, language and tag.
class StudioQuoteSheet extends StatelessWidget {
  final List<String> quotes;
  final String? current;
  final ValueChanged<String> onSelect;

  const StudioQuoteSheet({
    super.key,
    required this.quotes,
    required this.onSelect,
    this.current,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.7;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
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
            Row(
              children: [
                Icon(Icons.format_quote_rounded,
                    color: AppColors.accent, size: 22.w),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    S.t('pick_quote'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: quotes.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (_, i) {
                  final q = quotes[i];
                  final selected = q == current;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      onSelect(q);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: selected ? AppColors.accent : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              q,
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15.5.sp),
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            color: AppColors.accent,
                            size: 20.w,
                          ),
                        ],
                      ),
                    ),
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
