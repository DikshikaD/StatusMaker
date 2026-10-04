import 'package:status_maker/features/editor/data/quotes_data.dart';
import 'package:status_maker/studio/models/category_model.dart';
import 'package:status_maker/studio/models/language_model.dart';
import 'package:status_maker/studio/models/quote_model.dart';
import 'package:status_maker/studio/quotes/studio_quotes.dart';

/// The one place templates fetch quotes from. Combines the studio store with
/// the app's older per-category lists (so nothing the user already had
/// disappears), de-duplicates, and memoises per (category, language, tag).
///
/// Templates never hold quote text themselves: they ask here at build time,
/// which is what makes "change language" a re-fetch rather than a redesign.
class QuoteRepository {
  QuoteRepository._();

  static final Map<String, List<QuoteModel>> _memo = {};

  /// Quotes for [category] (a studio category id) in [language]. With [tag],
  /// only lines carrying that tag (Festival occasions); tagged lines are
  /// otherwise *excluded* from the untagged pool so a generic Festival card
  /// doesn't pick up "Eid Mubarak".
  static List<QuoteModel> forCategory(
    String category,
    AppLanguage language, {
    String? tag,
  }) {
    final key = '$category|${language.code}|${tag ?? ''}';
    final hit = _memo[key];
    if (hit != null) return hit;

    final out = <QuoteModel>[];
    final seen = <String>{};
    void add(QuoteModel q) {
      if (seen.add(q.text.trim())) out.add(q);
    }

    // 1. Studio lines, exact category + language (+ tag rule).
    for (final q in kStudioQuotes) {
      if (q.category != category || q.language != language) continue;
      if (tag != null ? q.tag != tag : q.tag != null) continue;
      add(q);
    }

    // 2. The pre-studio lists for the mapped legacy category. Untagged only.
    if (tag == null) {
      final legacy = studioCategory(category).legacyQuoteCategory;
      final map = language.isHindi ? kCategoryQuotesHi : kCategoryQuotes;
      for (final text in map[legacy] ?? const <String>[]) {
        add(QuoteModel(category: category, language: language, text: text));
      }
    }

    // 3. Never return an empty list — fall back to the general lines so a
    //    template always has something to show.
    if (out.isEmpty) {
      for (final text in (language.isHindi ? kGeneralQuotesHi : kGeneralQuotes)) {
        add(QuoteModel(category: category, language: language, text: text));
      }
    }

    return _memo[key] = List.unmodifiable(out);
  }

  /// Plain strings, for pickers that only need the words.
  static List<String> textsFor(String category, AppLanguage language,
          {String? tag}) =>
      [for (final q in forCategory(category, language, tag: tag)) q.text];

  /// The [index]-th quote, wrapping — so any template can ask for "quote #7"
  /// and get something even when a language has fewer lines.
  static QuoteModel pick(String category, AppLanguage language, int index,
      {String? tag}) {
    final list = forCategory(category, language, tag: tag);
    return list[index % list.length];
  }

  /// The same quote in the other language, by position in the pool. Pools
  /// are authored in matching order where a direct translation exists, so
  /// this usually *is* the translation; otherwise it's a fitting line.
  static QuoteModel counterpart(QuoteModel q) {
    final list = forCategory(q.category, q.language, tag: q.tag);
    final i = list.indexOf(q);
    return pick(q.category, q.language.other, i < 0 ? 0 : i, tag: q.tag);
  }
}
