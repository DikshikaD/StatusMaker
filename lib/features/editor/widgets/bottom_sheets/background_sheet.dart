import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/background_images.dart';
import 'package:status_maker/features/editor/data/remote_backgrounds.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/studio/background/background_presets.dart';
import 'package:status_maker/studio/presentation/studio_background_sheet.dart';

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

/// Labelled image categories shown in the sheet. Each pairs a category key in
/// the remote manifest (see [RemoteBackgrounds]) with a localized label key.
/// The file list comes from the manifest at runtime, so backgrounds can be
/// added by uploading them + updating manifest.json — no app release needed.
/// A category listed here but absent from the manifest is simply skipped.
const List<(String folder, String labelKey)> _imageCategories = [
  ('bhakti', 'bhakti'),
  ('morning', 'morning'),
  ('love', 'love'),
  ('festival', 'festival'),
  ('birthday', 'birthday'),
  ('random', 'random'),
];

class BackgroundSheet extends StatefulWidget {
  final ValueChanged<BackgroundState> onSelect;
  final VoidCallback onPickGallery;

  /// The current editor category, used to surface matching photo backgrounds.
  final String? category;

  const BackgroundSheet({
    super.key,
    required this.onSelect,
    required this.onPickGallery,
    this.category,
  });

  @override
  State<BackgroundSheet> createState() => _BackgroundSheetState();
}

class _BackgroundSheetState extends State<BackgroundSheet> {
  int _tab = 0; // 0 = presets, 1 = gallery

  // Category key -> filenames, from the remote manifest.
  Map<String, List<String>> _catFiles = const {};
  bool _loadingCats = true;

  // Full-size image currently being pre-fetched after a tap, so the tile can
  // show a spinner instead of the sheet appearing frozen.
  String? _busyUrl;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    if (forceRefresh) setState(() => _loadingCats = true);
    final files = await RemoteBackgrounds.load(forceRefresh: forceRefresh);
    if (!mounted) return;
    setState(() {
      _catFiles = files;
      _loadingCats = false;
    });
  }

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
        // Category-matched designed backgrounds (bundled). A soft scrim is
        // applied on the canvas so overlaid text stays readable.
        _sectionHeader(S.t('photo_backgrounds')),
        _grid([
          for (final path in backgroundImagesForCategory(widget.category))
            _assetTile(path),
        ]),
        SizedBox(height: 20.h),
        // Generated studio backgrounds matched to the editor's category —
        // painted recipes, so they cost no download and export at full
        // resolution. Each tile is a cached thumbnail (BackgroundThumb).
        _sectionHeader(S.t('designer_backgrounds')),
        _grid([
          for (final p in backgroundPresetsForLegacyCategory(widget.category))
            StudioBackgroundTile(
              state: p.toState(),
              onTap: () {
                widget.onSelect(p.toState());
                Navigator.of(context).pop();
              },
            ),
        ]),
        SizedBox(height: 20.h),
        // Solid colours & gradients (the currently available presets).
        _sectionHeader(S.t('colors')),
        _grid([
          _noneTile(),
          for (final bg in kBackgroundPresets) _colorTile(bg),
        ]),
        // Remote image categories (Bhakti, Morning, Love, …) — served from
        // Supabase Storage rather than bundled, so they cost no app size.
        if (_loadingCats)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 28.h),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_catFiles.isEmpty)
          _categoriesUnavailable()
        else
          for (final entry in _imageCategories)
            if ((_catFiles[entry.$1] ?? const []).isNotEmpty) ...[
              SizedBox(height: 20.h),
              _sectionHeader(S.t(entry.$2)),
              _grid([
                for (final file in _catFiles[entry.$1]!)
                  _remoteTile(entry.$1, file),
              ]),
            ],
      ],
    );
  }

  /// Shown when the manifest couldn't be fetched. These backgrounds are not
  /// bundled, so there is nothing to fall back to — offer a retry rather than
  /// silently rendering an empty sheet.
  Widget _categoriesUnavailable() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded,
              color: AppColors.textSecondary, size: 28.sp),
          SizedBox(height: 8.h),
          Text(
            S.t('backgrounds_offline'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: () => _loadCategories(forceRefresh: true),
            child: Text(S.t('retry')),
          ),
        ],
      ),
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

  /// Tile for a still-bundled asset image — used by the category-matched
  /// "Photo Backgrounds" strip, which reads `assets/backgrounds/` (a separate,
  /// much smaller folder than the `assets/categories/` set that moved remote).
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
            gaplessPlayback: true,
            // Decode at ~tile resolution, not full size — lighter grid.
            cacheWidth: 300,
            errorBuilder: (_, __, ___) =>
                ColoredBox(color: AppColors.cardLight),
          ),
        ),
      ),
    );
  }

  /// One remote background tile. Shows the small `thumb/` image; the full-size
  /// one is only ever fetched if the user actually picks it.
  Widget _remoteTile(String category, String file) {
    final thumb = RemoteBackgrounds.thumbUrl(category, file);
    final full = RemoteBackgrounds.fullUrl(category, file);
    final busy = _busyUrl == full;

    return GestureDetector(
      onTap: busy ? null : () => _pickRemote(full),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: thumb,
                fit: BoxFit.cover,
                // Decode at ~tile resolution, not full size — lighter grid.
                memCacheWidth: 300,
                placeholder: (_, __) => ColoredBox(color: AppColors.cardLight),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: AppColors.cardLight,
                  child: Icon(Icons.broken_image_outlined,
                      color: AppColors.textSecondary, size: 18.sp),
                ),
              ),
              if (busy)
                const ColoredBox(
                  color: Color(0x99000000),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Downloads (or reads from disk cache) the full-size background *before*
  /// applying it. Without this the canvas would briefly show an empty
  /// background — and an export taken in that window would bake in the gap.
  Future<void> _pickRemote(String fullUrl) async {
    setState(() => _busyUrl = fullUrl);
    // precacheImage reports a load failure through onError and then completes
    // normally — it never throws — so the failure has to be captured here or
    // an offline tap would apply a URL that renders (and exports) blank.
    var failed = false;
    try {
      await precacheImage(
        CachedNetworkImageProvider(fullUrl),
        context,
        onError: (_, __) => failed = true,
      );
      if (failed) throw StateError('background download failed');
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyUrl = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.t('background_download_failed'))),
      );
      return;
    }
    if (!mounted) return;
    // Remote backgrounds ride the existing `imagePath` field, which already
    // accepts http URLs (see canvasImage) and is left untouched by the save
    // flow's local-photo upload step.
    widget.onSelect(BackgroundState(imagePath: fullUrl));
    Navigator.of(context).pop();
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
