import "package:spendly/widgets/transaction_list_tile_theme.dart";
import "package:flutter/material.dart";

class FlowThemes extends StatelessWidget {
  final Widget child;

  const FlowThemes({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TransactionListTileTheme(
      data: const TransactionListTileThemeData(
        useCategoryNameForUntitledTransactions: false,
        useAccountIconForLeading: false,
        showExternalSource: false,
        showCategory: true,
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        spacing: 12.0,
        titleSpacing: 2.0,
      ),
      child: child,
    );
  }
}
