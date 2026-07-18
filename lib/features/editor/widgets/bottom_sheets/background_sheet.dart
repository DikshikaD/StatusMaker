import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _segment(),
            const SizedBox(height: 16),
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
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.darkTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [tab('Presets', 0), tab('Gallery', 1)]),
    );
  }

  Widget _presetsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // +1 for the leading "None" tile.
      itemCount: kBackgroundPresets.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (_, i) {
        if (i == 0) return _noneTile();
        final bg = kBackgroundPresets[i - 1];
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
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
          ),
        );
      },
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
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hide_image_outlined, color: Colors.white70, size: 22),
            SizedBox(height: 4),
            Text('None',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _galleryTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: widget.onPickGallery,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined, color: Colors.white, size: 30),
              SizedBox(height: 8),
              Text(
                'Choose from Gallery',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
