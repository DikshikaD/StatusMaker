import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';

/// The default bottom bar: the only three things you can add. Big targets,
/// evenly spaced, thumb-reachable.
class AddBar extends StatelessWidget {
  final VoidCallback onBackground;
  final VoidCallback onPhoto;
  final VoidCallback onText;
  final VoidCallback onQuotes;

  const AddBar({
    super.key,
    required this.onBackground,
    required this.onPhoto,
    required this.onText,
    required this.onQuotes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _item(Icons.wallpaper_rounded, 'Background', onBackground),
            _item(Icons.add_photo_alternate_rounded, 'Photo', onPhoto),
            _item(Icons.text_fields_rounded, 'Text', onText),
            _item(Icons.format_quote_rounded, 'Quotes', onQuotes),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.darkTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
