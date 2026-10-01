import "package:spendly/data/flow_icon.dart";
import "package:spendly/data/setup/default_accounts.dart";
import "package:spendly/data/setup/default_categories.dart";
import "package:spendly/entity/account.dart";
import "package:spendly/entity/category.dart";
import "package:material_symbols_icons_flow/symbols.dart";

/// Falls back to [fallback]
FlowIconData guessPresetIcon(
  String name, {
  FlowIconData fallback = const IconFlowIcon(Symbols.circle_rounded),
}) {
  name = name.trim().toLowerCase();

  for (final Account accountPreset in getAccountPresets("USD")) {
    if (accountPreset.name.toLowerCase() == name) {
      return accountPreset.icon;
    }
  }

  for (final Category categoryPreset in getCategoryPresets()) {
    if (categoryPreset.name.toLowerCase() == name) {
      return categoryPreset.icon;
    }
  }

  return fallback;
}
