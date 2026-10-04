import 'package:status_maker/studio/models/language_model.dart';

/// One ready-made line of text. Quotes are stored on their own — never inside
/// a template — so a template can ask for "a Good Morning quote in Hindi" at
/// build time and the same layout serves every language.
class QuoteModel {
  /// Studio category id (see `CategoryModel.id`), e.g. `'morning'`.
  final String category;
  final AppLanguage language;
  final String text;

  /// Optional sub-theme, used where one category spans several distinct
  /// occasions — Festival quotes are tagged `diwali`, `holi`, `rakhi`,
  /// `independence`, … so a Diwali background never carries a Holi line.
  final String? tag;

  const QuoteModel({
    required this.category,
    required this.language,
    required this.text,
    this.tag,
  });

  /// Rough visual weight of the line, used to pick a font size that fits the
  /// slot: Devanagari runs wider per glyph than Latin, so it counts for more.
  int get weight {
    var w = 0;
    for (final r in text.runes) {
      w += (r >= 0x0900 && r <= 0x097F) ? 2 : 1;
    }
    return w;
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'language': language.code,
        'text': text,
        if (tag != null) 'tag': tag,
      };

  factory QuoteModel.fromJson(Map<String, dynamic> j) => QuoteModel(
        category: j['category'] as String,
        language: AppLanguage.fromCode(j['language'] as String?),
        text: j['text'] as String,
        tag: j['tag'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is QuoteModel &&
      other.category == category &&
      other.language == language &&
      other.text == text &&
      other.tag == tag;

  @override
  int get hashCode => Object.hash(category, language, text, tag);
}
