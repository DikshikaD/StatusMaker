import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/utils/responsive.dart';

class CommunitySubmissionScreen extends StatelessWidget {
  const CommunitySubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Share Status', style: TextStyle(fontSize: 16.sp)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
            Container(
              height: 380.h,
              width: 240.w,
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20.r, offset: Offset(0, 10.h))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Image.network(
                  'https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=2000&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  cacheWidth: 900,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Container(color: AppColors.cardLight),
                  errorBuilder: (_, __, ___) => Center(child: Icon(Icons.image, size: 50.w, color: AppColors.border)),
                ),
              ),
            ),
            SizedBox(height: AppDimensions.paddingXLarge),
            TextField(
              decoration: InputDecoration(
                hintText: 'Add a caption or tags...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20.w),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Ensure your design follows our community originality guidelines.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDimensions.paddingXLarge),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: () {
                   Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                  elevation: 0,
                ),
                child: Text('Submit to Feed', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
