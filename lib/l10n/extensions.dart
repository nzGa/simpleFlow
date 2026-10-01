import "package:spendly/l10n/flow_localizations.dart";
import "package:spendly/l10n/supported_languages.dart";
import "package:flutter/widgets.dart";

extension L10nHelper on BuildContext {
  FlowLocalizations get l => FlowLocalizations.of(this);
}

extension Underscore on Locale {
  /// Example outcome:
  /// * en
  /// * fr_FR
  /// * mn_Mong_MN
  String get code => [languageCode, scriptCode, countryCode].nonNulls.join("_");

  /// English name
  String get name => supportedLanguages[this]?.$1 ?? "Unknown";

  /// Language name in the language
  String get endonym => supportedLanguages[this]?.$2 ?? "Unknown";
}

extension L10nStringHelper on String {
  /// Returns localized version of [this].
  ///
  /// Same as calling context.l.get([this])
  String t(BuildContext context, [dynamic replace]) =>
      context.l.get(this, replace: replace);

  /// Returns localized version of [this].
  ///
  /// This does not require a context
  String tr([dynamic replace]) =>
      FlowLocalizations.getTransalation(this, replace: replace);
}
