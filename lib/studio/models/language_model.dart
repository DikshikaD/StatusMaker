import 'package:status_maker/core/localization/strings.dart';

/// The languages the studio can author content in. Mirrors the two codes the
/// app-wide [S] localisation already persists ('en' / 'hi'), so switching the
/// app language and switching a template's language agree on what a language
/// *is* — without the studio reaching into the UI strings table.
enum AppLanguage {
  en('en', 'English', 'English'),
  hi('hi', 'Hindi', 'हिंदी');

  const AppLanguage(this.code, this.englishName, this.nativeName);

  /// Two-letter code, identical to the value stored by [S.set].
  final String code;
  final String englishName;
  final String nativeName;

  bool get isHindi => this == AppLanguage.hi;

  /// The other language — what a "switch language" toggle flips to.
  AppLanguage get other => isHindi ? AppLanguage.en : AppLanguage.hi;

  static AppLanguage fromCode(String? code) =>
      code == 'hi' ? AppLanguage.hi : AppLanguage.en;

  /// The app's current language.
  static AppLanguage get current => fromCode(S.lang.value);
}

/// Descriptive wrapper used by pickers (a language row needs a label in both
/// its own script and the app's, plus a stable id).
class LanguageModel {
  final AppLanguage language;

  const LanguageModel(this.language);

  String get id => language.code;
  String get nativeName => language.nativeName;
  String get englishName => language.englishName;

  /// Label for the current UI language: "Hindi" in an English UI, "हिंदी" in
  /// a Hindi one (and vice versa for English).
  String get label =>
      AppLanguage.current == AppLanguage.hi ? nativeName : englishName;
}

/// Every supported language, in picker order.
const List<LanguageModel> kLanguages = [
  LanguageModel(AppLanguage.en),
  LanguageModel(AppLanguage.hi),
];
