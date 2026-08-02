import 'dart:math';

import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/data/quotes_data.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// Tap-to-add quote suggestions for the current category. Zero typing.
///
/// Shows at least [_kMinQuotes] quotes, prioritising the selected category
/// (or a random spread when no category is selected). The refresh button
/// rotates through a large de-duplicated pool so the user keeps seeing fresh,
/// non-repeating lines.
class QuotesSheet extends StatefulWidget {
  final String? category;
  final ValueChanged<String> onSelect;

  const QuotesSheet({super.key, required this.category, required this.onSelect});

  @override
  State<QuotesSheet> createState() => _QuotesSheetState();
}

class _QuotesSheetState extends State<QuotesSheet> {
  /// Minimum number of quotes to display at once.
  static const int _kMinQuotes = 25;

  final Random _rng = Random();

  /// Full de-duplicated, shuffled pool (category lines first).
  late List<String> _pool;

  /// Start index of the currently-shown window into [_pool].
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _pool = _buildPool();
  }

  /// Category quotes (shuffled) first, then everything else (shuffled).
  List<String> _buildPool() {
    final priority = quotesForCategory(widget.category).toSet().toList()
      ..shuffle(_rng);
    final prioritySet = priority.toSet();
    final others = quotePoolForCategory(widget.category)
        .where((q) => !prioritySet.contains(q))
        .toList()
      ..shuffle(_rng);
    return [...priority, ...others];
  }

  int get _windowSize =>
      _pool.length < _kMinQuotes ? _pool.length : _kMinQuotes;

  /// The quotes currently on screen — a window of [_windowSize] starting at
  /// [_offset], wrapping if needed. Never contains duplicates.
  List<String> get _visible {
    if (_pool.isEmpty) return const [];
    final n = _windowSize;
    return [for (int i = 0; i < n; i++) _pool[(_offset + i) % _pool.length]];
  }

  /// Advance to the next, non-overlapping window. Once the pool is exhausted,
  /// reshuffle for a fresh spread.
  void _refresh() {
    setState(() {
      final next = _offset + _windowSize;
      if (next + _windowSize > _pool.length) {
        _pool = _buildPool();
        _offset = 0;
      } else {
        _offset = next;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final quotes = _visible;
    final maxH = MediaQuery.of(context).size.height * 0.7;
    final hasCategory =
        widget.category != null && widget.category!.isNotEmpty;

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
                // Both labels must yield rather than push the refresh button
                // off-screen — localized strings plus a category chip can
                // exceed the sheet's content width.
                Flexible(
                  child: Text(
                    S.t('tap_quote'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                if (hasCategory)
                  Flexible(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        S.cat(widget.category!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                SizedBox(width: 8.w),
                // Refresh → shows a fresh, non-repeating set of quotes.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _refresh,
                  child: Container(
                    width: 34.w,
                    height: 34.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(Icons.refresh_rounded,
                        color: AppColors.accent, size: 20.w),
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
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      widget.onSelect(q);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              q,
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 16.sp),
                            ),
                          ),
                          Icon(Icons.add_circle_outline,
                              color: AppColors.accent, size: 22.w),
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
