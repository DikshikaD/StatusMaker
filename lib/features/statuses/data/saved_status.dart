import 'package:status_maker/features/editor/data/status_design.dart';

/// A single row from the Supabase `statuses` table — one saved design.
///
/// The [design] map is the full, still-editable composition (background, texts,
/// images, elements, frame). The feed and the "My Creations" grid only need
/// [thumbUrl] to draw a preview; [design] is decoded to a [StatusDesign] lazily
/// (via [toDesign]) when the user taps Customize and we reopen the editor.
class SavedStatus {
  final String id;
  final String? userId;
  final String? title;
  final String? category;
  final Map<String, dynamic> design;
  final String? thumbUrl;
  final bool isPublic;
  final String? remixOf;
  final int likesCount;
  final DateTime? createdAt;

  const SavedStatus({
    required this.id,
    this.userId,
    this.title,
    this.category,
    this.design = const {},
    this.thumbUrl,
    this.isPublic = false,
    this.remixOf,
    this.likesCount = 0,
    this.createdAt,
  });

  /// Decode the stored JSON back into an editable design.
  StatusDesign toDesign() =>
      StatusDesign.fromJson(Map<String, dynamic>.from(design));

  factory SavedStatus.fromRow(Map<String, dynamic> row) {
    return SavedStatus(
      id: row['id'] as String,
      userId: row['user_id'] as String?,
      title: row['title'] as String?,
      category: row['category'] as String?,
      design: (row['design'] as Map?)?.cast<String, dynamic>() ?? const {},
      thumbUrl: row['thumb_url'] as String?,
      isPublic: row['is_public'] as bool? ?? false,
      remixOf: row['remix_of'] as String?,
      likesCount: (row['likes_count'] as num?)?.toInt() ?? 0,
      createdAt: row['created_at'] == null
          ? null
          : DateTime.tryParse(row['created_at'].toString()),
    );
  }
}
