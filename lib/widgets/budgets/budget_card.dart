import "package:spendly/data/budget_progress.dart";
import "package:spendly/data/exchange_rates.dart";
import "package:spendly/entity/budget.dart";
import "package:spendly/entity/transaction.dart";
import "package:spendly/l10n/flow_localizations.dart";
import "package:spendly/services/budget.dart";
import "package:spendly/services/exchange_rates.dart";
import "package:spendly/widgets/analytics/bullet_chart.dart";
import "package:spendly/widgets/analytics/insight_card.dart";
import "package:spendly/widgets/budgets/budget_category_chips.dart";
import "package:spendly/widgets/general/money_text.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:material_symbols_icons_flow/symbols.dart";
import "package:moment_dart/moment_dart.dart";

/// Shows a budget's spent-vs-amount for its current period.
///
/// Watches the budget's matching transactions, so it live-updates as
/// transactions change.
class BudgetCard extends StatelessWidget {
  final Budget budget;

  const BudgetCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final ExchangeRates? rates = ExchangeRatesService()
        .getPrimaryCurrencyRates();

    return StreamBuilder<List<Transaction>>(
      stream: BudgetService()
          .transactionsQb(budget)
          .watch(triggerImmediately: true)
          .map((event) => event.find()),
      builder: (context, snapshot) {
        // The stream already holds this period's transactions, so this reuses
        // them rather than letting `computeProgress` run its own query.
        final BudgetProgress progress = BudgetService().computeProgress(
          budget,
          rates: rates,
          transactions: snapshot.data ?? const [],
        );

        return InsightCard(
          icon: Symbols.money_bag_rounded,
          label: budget.name,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MoneyText(progress.spent),
              const Text(" / "),
              MoneyText(progress.limit),
            ],
          ),
          subtitle: _periodLabel(),
          onTap: () => context.push("/budgets/${budget.id}"),
          child: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              BudgetCategoryChips(
                categories: budget.categories.toList(),
                allSpendingLabel: "budget.categories.allShort".t(context),
              ),
              const SizedBox(height: 12.0),
              BulletChart(
                value: progress.spent.amount,
                target: progress.limit.amount,
                pending: progress.pendingSpent.amount,
                paceRatio: progress.isCurrent ? progress.periodElapsed : null,
              ),
            ],
          ),
        );
      },
    );
  }

  String _periodLabel() {
    final TimeRange range = BudgetService().currentPeriod(budget);

    return switch (range) {
      MonthTimeRange monthTimeRange => monthTimeRange.from.format(
        payload: monthTimeRange.from.isAtSameYearAs(DateTime.now())
            ? "MMMM"
            : "MMMM YYYY",
      ),
      YearTimeRange yearTimeRange => yearTimeRange.year.toString(),
      _ => "${range.from.toMoment().ll} -> ${range.to.toMoment().ll}",
    };
  }
}
