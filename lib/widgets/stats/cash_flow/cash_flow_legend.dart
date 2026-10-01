import "package:spendly/data/money.dart";
import "package:spendly/theme/theme.dart";
import "package:spendly/widgets/analytics/sankey_diagram.dart";
import "package:spendly/widgets/general/frame.dart";
import "package:spendly/widgets/general/money_text.dart";
import "package:flutter/material.dart";

/// A color-swatch + label + amount legend for one side of the cash-flow Sankey.
class CashFlowLegend extends StatelessWidget {
  final List<SankeyDatum> data;
  final String currency;

  const CashFlowLegend({super.key, required this.data, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Frame(
      child: Column(
        children: data.map((datum) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(
                  width: 12.0,
                  height: 12.0,
                  decoration: BoxDecoration(
                    color: datum.color,
                    borderRadius: .all(Radius.circular(3.0)),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    datum.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8.0),
                MoneyText(
                  Money(datum.value, currency),
                  style: context.textTheme.bodyMedium?.semi(context),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
