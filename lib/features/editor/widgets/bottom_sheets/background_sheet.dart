import 'package:flutter/material.dart';
import 'package:status_maker/core/constants/app_assets.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// Built-in backgrounds — solid colours and gradients. No assets needed.
const List<BackgroundState> kBackgroundPresets = [
  BackgroundState(color: Color(0xFF0F172A)),
  BackgroundState(color: Color(0xFF000000)),
  BackgroundState(color: Color(0xFFFFFFFF)),
  BackgroundState(color: Color(0xFFE38870)),
  BackgroundState(color: Color(0xFF1E3A8A)),
  BackgroundState(color: Color(0xFF4A148C)),
  BackgroundState(gradientColors: [Color(0xFFFF9A9E), Color(0xFFFAD0C4)]),
  BackgroundState(gradientColors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)]),
  BackgroundState(gradientColors: [Color(0xFFFBAB7E), Color(0xFFF7CE68)]),
  BackgroundState(gradientColors: [Color(0xFF43E97B), Color(0xFF38F9D7)]),
  BackgroundState(gradientColors: [Color(0xFF4FACFE), Color(0xFF00F2FE)]),
  BackgroundState(gradientColors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
  BackgroundState(gradientColors: [Color(0xFF0F2027), Color(0xFF2C5364)]),
  BackgroundState(gradientColors: [Color(0xFFF83600), Color(0xFFFE8C00)]),
  BackgroundState(gradientColors: [Color(0xFF232526), Color(0xFF414345)]),
];

/// Applied by the "None" tile to clear any picked image back to a plain colour.
const BackgroundState kNoBackground = BackgroundState(color: Color(0xFF0F172A));

/// Image background categories, each with its bundled asset paths.
class BackgroundCategory {
  final String labelKey;
  final List<String> assets;
  const BackgroundCategory(this.labelKey, this.assets);
}

const List<BackgroundCategory> kBackgroundCategories = [
  BackgroundCategory('morning', AppAssets.morningBackgrounds),
  BackgroundCategory('festival', AppAssets.festivalBackgrounds),
  BackgroundCategory('love', AppAssets.loveBackgrounds),
  BackgroundCategory('birthday', AppAssets.birthdayBackgrounds),
];

class BackgroundSheet extends StatefulWidget {
  final ValueChanged<BackgroundState> onSelect;
  final VoidCallback onPickGallery;

  const BackgroundSheet({
    super.key,
    required this.onSelect,
    required this.onPickGallery,
  });

  @override
  State<BackgroundSheet> createState() => _BackgroundSheetState();
}

class _BackgroundSheetState extends State<BackgroundSheet> {
  int _tab = 0; // 0 = presets, 1 = gallery

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.78;

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
            SizedBox(height: 16.h),
            _segment(),
            SizedBox(height: 16.h),
            // Scrollable so the grid never overflows / overlaps.
            Flexible(
              child: SingleChildScrollView(
                child: _tab == 0 ? _presetsGrid() : _galleryTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment() {
    Widget tab(String label, int index) {
      final selected = _tab == index;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = index),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(children: [tab(S.t('presets'), 0), tab(S.t('gallery'), 1)]),
    );
  }

  Widget _presetsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Solid colours & gradients (the currently available presets).
        _sectionHeader(S.t('colors')),
        _grid([
          _noneTile(),
          for (final bg in kBackgroundPresets) _colorTile(bg),
        ]),
        // Image categories: Morning, Festival, Love.
        for (final cat in kBackgroundCategories) ...[
          SizedBox(height: 20.h),
          _sectionHeader(S.t(cat.labelKey)),
          _grid([for (final path in cat.assets) _assetTile(path)]),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _grid(List<Widget> children) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 0.72,
      children: children,
    );
  }

  Widget _colorTile(BackgroundState bg) {
    return GestureDetector(
      onTap: () {
        widget.onSelect(bg);
        Navigator.of(context).pop();
      },
      child: Container(
        decoration: BoxDecoration(
          color: bg.color,
          gradient: bg.isGradient
              ? LinearGradient(
                  colors: bg.gradientColors!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
      ),
    );
  }

  Widget _assetTile(String path) {
    return GestureDetector(
      onTap: () {
        widget.onSelect(BackgroundState(assetPath: path));
        Navigator.of(context).pop();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Image.asset(
            path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                ColoredBox(color: AppColors.cardLight),
          ),
        ),
      ),
    );
  }

  /// Clears any picked image and resets to a plain background.
  Widget _noneTile() {
    return GestureDetector(
      onTap: () {
        widget.onSelect(kNoBackground);
        Navigator.of(context).pop();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hide_image_outlined,
                color: AppColors.textSecondary, size: 22.w),
            SizedBox(height: 4.h),
            Text(S.t('none'),
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 11.sp)),
          ],
        ),
      ),
    );
  }

  Widget _galleryTab() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: GestureDetector(
        onTap: widget.onPickGallery,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 22.h),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined,
                  color: Colors.white, size: 30.w),
              SizedBox(height: 8.h),
              Text(
                S.t('choose_gallery'),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
