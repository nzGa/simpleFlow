import "package:spendly/data/flow_icon.dart";
import "package:spendly/l10n/extensions.dart";
import "package:spendly/theme/theme.dart";
import "package:spendly/widgets/general/empty_state.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons_flow/symbols.dart";

class NoTransactions extends StatelessWidget {
  final bool isFilterModified;

  const NoTransactions({super.key, required this.isFilterModified});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      leading: Text(
        "tabs.home.noTransactions".t(context),
        textAlign: TextAlign.center,
        style: context.textTheme.headlineSmall,
      ),
      icon: FlowIconData.icon(Symbols.family_star_rounded),
      subtitle: isFilterModified
          ? Text("tabs.home.noTransactions.tryChangingFilters".t(context))
          : null,
    );
  }
}
