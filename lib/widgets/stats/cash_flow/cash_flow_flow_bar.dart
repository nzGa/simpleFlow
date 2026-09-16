import "package:flow/theme/theme.dart";
import "package:flutter/material.dart";

/// Single stacked bar whose income and expense segments are sized by their
/// share of the period's total movement. Degrades gracefully when either side
/// is zero, never dividing by zero.
class CashFlowFlowBar extends StatelessWidget {
  final double income;
  final double expense;

  const CashFlowFlowBar({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final Color incomeColor = context.flowColors.income;
    final Color expenseColor = context.flowColors.expense;

    Widget bar(Color color) => ClipRRect(
      borderRadius: .all(Radius.circular(6.0)),
      child: SizedBox(height: 12.0, child: ColoredBox(color: color)),
    );

    // A zero side must not keep a 1-flex sliver — that reads as "some
    // income" next to a 0,00 label. Show only the side that moved.
    if (income <= 0 && expense <= 0) {
      return bar(context.colorScheme.onSurface.withAlpha(0x1f));
    }
    if (income <= 0) return bar(expenseColor);
    if (expense <= 0) return bar(incomeColor);

    final double total = income + expense;
    final int incomeFlex = (income / total * 1000).round().clamp(1, 999);
    final int expenseFlex = (expense / total * 1000).round().clamp(1, 999);

    return ClipRRect(
      borderRadius: .all(Radius.circular(6.0)),
      child: SizedBox(
        height: 12.0,
        child: Row(
          crossAxisAlignment: .stretch,
          children: [
            Expanded(
              flex: incomeFlex,
              child: ColoredBox(color: incomeColor),
            ),
            const SizedBox(width: 3.0),
            Expanded(
              flex: expenseFlex,
              child: ColoredBox(color: expenseColor),
            ),
          ],
        ),
      ),
    );
  }
}
