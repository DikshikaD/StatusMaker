import 'package:flutter/material.dart';
import 'package:status_maker/core/localization/strings.dart';

/// A studio content category. Each one has its own visual identity (see the
/// background and layout presets), its own quote pool, and a mapping to the
/// older category names the rest of the app already uses for quotes and
/// saved-status tagging.
class CategoryModel {
  /// Stable id used in configs, quotes and saved designs. Never localised.
  final String id;
  final String nameEn;
  final String nameHi;
  final IconData icon;

  /// Hue for the category chip — composited at low alpha over the surface,
  /// exactly like the Create tab's theme discs.
  final Color tint;

  /// The pre-studio quote category (keys of `kCategoryQuotes`) that best
  /// matches. Lets the free editor's Quotes sheet and `StatusRepository`'s
  /// category column keep working with their existing vocabulary.
  final String legacyQuoteCategory;

  const CategoryModel({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.icon,
    required this.tint,
    required this.legacyQuoteCategory,
  });

  String get name => S.isHi ? nameHi : nameEn;
}

/// Every studio category, in the order they appear on screen.
const List<CategoryModel> kStudioCategories = [
  CategoryModel(
    id: 'morning',
    nameEn: 'Good Morning',
    nameHi: 'सुप्रभात',
    icon: Icons.wb_sunny_outlined,
    tint: Color(0xFFF59E0B),
    legacyQuoteCategory: 'Good Morning',
  ),
  CategoryModel(
    id: 'goodnight',
    nameEn: 'Good Night',
    nameHi: 'शुभ रात्रि',
    icon: Icons.nightlight_round,
    tint: Color(0xFF6366F1),
    legacyQuoteCategory: 'Good Night',
  ),
  CategoryModel(
    id: 'bhakti',
    nameEn: 'Bhakti',
    nameHi: 'भक्ति',
    icon: Icons.self_improvement,
    tint: Color(0xFFF97316),
    legacyQuoteCategory: 'Devotional',
  ),
  CategoryModel(
    id: 'motivation',
    nameEn: 'Motivation',
    nameHi: 'प्रेरणा',
    icon: Icons.bolt_outlined,
    tint: Color(0xFFEAB308),
    legacyQuoteCategory: 'Motivation',
  ),
  CategoryModel(
    id: 'success',
    nameEn: 'Success',
    nameHi: 'सफलता',
    icon: Icons.emoji_events_outlined,
    tint: Color(0xFFD4AF37),
    legacyQuoteCategory: 'Motivation',
  ),
  CategoryModel(
    id: 'business',
    nameEn: 'Business',
    nameHi: 'बिज़नेस',
    icon: Icons.business_center_outlined,
    tint: Color(0xFF64748B),
    legacyQuoteCategory: 'Business',
  ),
  CategoryModel(
    id: 'birthday',
    nameEn: 'Birthday',
    nameHi: 'जन्मदिन',
    icon: Icons.cake_outlined,
    tint: Color(0xFFEC4899),
    legacyQuoteCategory: 'Birthday',
  ),
  CategoryModel(
    id: 'festival',
    nameEn: 'Festival',
    nameHi: 'त्योहार',
    icon: Icons.celebration_outlined,
    tint: Color(0xFFEF4444),
    legacyQuoteCategory: 'Festival',
  ),
  CategoryModel(
    id: 'love',
    nameEn: 'Love',
    nameHi: 'प्यार',
    icon: Icons.favorite_outline,
    tint: Color(0xFFE11D48),
    legacyQuoteCategory: 'Love',
  ),
  CategoryModel(
    id: 'heartbreak',
    nameEn: 'Heartbreak',
    nameHi: 'दिल की बात',
    icon: Icons.heart_broken_outlined,
    tint: Color(0xFF475569),
    legacyQuoteCategory: 'Love',
  ),
  CategoryModel(
    id: 'friendship',
    nameEn: 'Friendship',
    nameHi: 'दोस्ती',
    icon: Icons.people_outline,
    tint: Color(0xFF14B8A6),
    legacyQuoteCategory: 'General',
  ),
  CategoryModel(
    id: 'wishes',
    nameEn: 'Wishes',
    nameHi: 'शुभकामनाएँ',
    icon: Icons.card_giftcard_outlined,
    tint: Color(0xFF8B5CF6),
    legacyQuoteCategory: 'General',
  ),
  CategoryModel(
    id: 'nature',
    nameEn: 'Nature',
    nameHi: 'प्रकृति',
    icon: Icons.park_outlined,
    tint: Color(0xFF22C55E),
    legacyQuoteCategory: 'Suvichar',
  ),
  CategoryModel(
    id: 'minimal',
    nameEn: 'Minimal',
    nameHi: 'मिनिमल',
    icon: Icons.crop_square_outlined,
    tint: Color(0xFF94A3B8),
    legacyQuoteCategory: 'Suvichar',
  ),
  CategoryModel(
    id: 'premium_dark',
    nameEn: 'Dark',
    nameHi: 'डार्क',
    icon: Icons.diamond_outlined,
    tint: Color(0xFF0EA5E9),
    legacyQuoteCategory: 'Suvichar',
  ),
];

/// Looks a category up by [id]; falls back to the first category rather than
/// throwing, so a stale id in a saved design can never crash a screen.
CategoryModel studioCategory(String id) {
  for (final c in kStudioCategories) {
    if (c.id == id) return c;
  }
  return kStudioCategories.first;
}

/// Maps the Create tab's theme names (and the older quote-category names the
/// rest of the app uses) onto studio category ids, so a theme's screen can
/// list the generated designs that belong to it. Null = no studio content.
const Map<String, String> kThemeToStudioCategory = {
  'Good Morning': 'morning',
  'Morning': 'morning',
  'Suprabhat': 'morning',
  'Good Night': 'goodnight',
  'Devotional': 'bhakti',
  'Motivation': 'motivation',
  'Business': 'business',
  'Birthday': 'birthday',
  'Festival': 'festival',
  'Love': 'love',
  'Suvichar': 'minimal',
  'Success': 'success',
  'Friendship': 'friendship',
  'Wishes': 'wishes',
  'Nature': 'nature',
  'Heartbreak': 'heartbreak',
  'Minimal': 'minimal',
  'Dark': 'premium_dark',
};

String? studioCategoryForTheme(String? theme) => kThemeToStudioCategory[theme];
