import "dart:math" as math;

import "package:auto_size_text/auto_size_text.dart";
import "package:flow/data/flow_standard_report.dart";
import "package:flow/data/money.dart";
import "package:flow/data/setup/default_categories.dart";
import "package:flow/entity/category.dart";
import "package:flow/l10n/extensions.dart";
import "package:flow/objectbox.dart";
import "package:flow/objectbox/actions.dart";
import "package:flow/theme/theme.dart";
import "package:flow/utils/primary_currency_dependent_state.dart";
import "package:flow/widgets/analytics/sankey_diagram.dart";
import "package:flow/widgets/general/frame.dart";
import "package:flow/widgets/general/list_header.dart";
import "package:flow/widgets/general/spinner.dart";
import "package:flow/widgets/home/stats/info_card_with_delta.dart";
import "package:flow/widgets/stats/cash_flow/cash_flow_legend.dart";
import "package:flow/widgets/stats/cash_flow/cash_flow_summary.dart";
import "package:flow/widgets/stats/missing_rates_notice.dart";
import "package:flow/widgets/stats/stats_app_bar.dart";
import "package:flow/widgets/stats/stats_empty_state.dart";
import "package:flow/widgets/time_range_selector.dart";
import "package:flutter/material.dart";
import "package:moment_dart/moment_dart.dart";

/// Cash-flow Sankey in the classic budget shape.
///
/// Gross income (income categories stacked in one bar) peels taxes when
/// present, continues as net income, then fans out to expense categories
/// plus surplus. A month with no income (or spending above income) keeps
/// the two-column "From reserves" fallback so the chart stays readable.
/// Category icon colors are ignored: left bars use
/// [sankeyIncomePalette], expenses use [sankeyExpensePalette], and
/// surplus uses the theme income color so it cannot collide with either.
class CashFlowPage extends StatefulWidget {
  const CashFlowPage({super.key});

  @override
  State<CashFlowPage> createState() => _CashFlowPageState();
}

class _CashFlowPageState extends State<CashFlowPage>
    with PrimaryCurrencyDependentState<CashFlowPage> {
  static const int _maxIncomeNodes = 4;
  static const int _maxExpenseNodes = 6;

  TimeRange range = TimeRange.thisMonth();

  bool busy = false;
  bool missingRates = false;
  bool failed = false;

  BudgetSankeyLayout layout = const BudgetSankeyLayout(left: [], right: []);
  double totalIncome = 0.0;
  double totalExpense = 0.0;

  /// Drives the forecast headline and the daily-average cards. Fetched
  /// alongside the Sankey aggregation but kept independent, so the averages
  /// still render if the per-category pass fails.
  FlowStandardReport? report;

  final AutoSizeGroup _averagesGroup = AutoSizeGroup();

  @override
  Widget build(BuildContext context) {
    final bool hasData = !layout.isEmpty;
    final double net = totalIncome - totalExpense;

    final FlowStandardReport? stats = report;

    // The forecast only means something when the range still has days left to
    // run and there's movement to project; for a closed range the projection
    // equals the actual total, so it's folded into the summary only here.
    Money? forecast;
    if (stats != null &&
        range.contains(DateTime.now()) &&
        (stats.incomeSum.amount != 0 || stats.expenseSum.amount != 0)) {
      forecast = stats.currentExpenseSumForecast ?? stats.expenseSum;
    }

    return Scaffold(
      appBar: StatsAppBar(title: "tabs.stats.analytics.cashFlow".t(context)),
      body: SafeArea(
        child: busy && layout.isEmpty
            ? const Spinner.center()
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    const SizedBox(height: 16.0),
                    Frame(
                      child: TimeRangeSelector(
                        initialValue: range,
                        onChanged: _updateRange,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    CashFlowSummary(
                      income: Money(totalIncome, primaryCurrency),
                      expense: Money(totalExpense, primaryCurrency),
                      net: Money(net, primaryCurrency),
                      forecast: forecast,
                      forecastComparison: stats?.previousExpenseSum,
                      forecastLabel: "tabs.stats.intervalReport.forecast".t(
                        context,
                        range.format(),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    if (failed)
                      StatsEmptyState(
                        message: "tabs.stats.analytics.cashFlow.loadFailed".t(
                          context,
                        ),
                      )
                    else if (hasData) ...[
                      Frame(
                        child: SankeyDiagram.fromLayout(
                          layout: layout,
                          height: math.max(
                            layout.isClassic ? 320.0 : 280.0,
                            math.max(layout.left.length, layout.right.length) *
                                40.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      ListHeader("tabs.stats.analytics.income".t(context)),
                      const SizedBox(height: 8.0),
                      CashFlowLegend(
                        data: layout.left,
                        currency: primaryCurrency,
                      ),
                      const SizedBox(height: 16.0),
                      ListHeader("tabs.stats.analytics.spending".t(context)),
                      const SizedBox(height: 8.0),
                      CashFlowLegend(
                        data: [?layout.taxes, ...layout.right],
                        currency: primaryCurrency,
                      ),
                    ] else
                      StatsEmptyState(
                        message: "tabs.stats.analytics.cashFlow.empty".t(
                          context,
                        ),
                      ),
                    if (stats != null &&
                        (stats.incomeSum.amount != 0 ||
                            stats.expenseSum.amount != 0)) ...[
                      const SizedBox(height: 24.0),
                      _buildAverages(context, stats),
                    ],
                    if (missingRates) ...[
                      const SizedBox(height: 12.0),
                      MissingRatesNotice(
                        message: "tabs.stats.analytics.missingRatesAmounts".t(
                          context,
                        ),
                      ),
                    ],
                    const SizedBox(height: 96.0),
                  ],
                ),
              ),
      ),
    );
  }

  void _updateRange(TimeRange value) {
    if (value == range) return;
    range = value;
    fetch();
  }

  /// Per-day averages for expense, income, and flow, each with a delta against
  /// the previous comparable period when one exists.
  Widget _buildAverages(BuildContext context, FlowStandardReport stats) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        ListHeader("tabs.stats.intervalReport.averages@day".t(context)),
        const SizedBox(height: 8.0),
        Frame(
          child: Column(
            spacing: 16.0,
            children: [
              Row(
                spacing: 16.0,
                children: [
                  Expanded(
                    child: InfoCardWithDelta(
                      title: "tabs.stats.intervalReport.averages.expense".t(
                        context,
                      ),
                      autoSizeGroup: _averagesGroup,
                      money: stats.dailyAvgExpenditure,
                      previousMoney: stats.previousDailyAvgExpenditure,
                      invertDelta: true,
                    ),
                  ),
                  Expanded(
                    child: InfoCardWithDelta(
                      title: "tabs.stats.intervalReport.averages.income".t(
                        context,
                      ),
                      autoSizeGroup: _averagesGroup,
                      money: stats.dailyAvgIncome,
                      previousMoney: stats.previousDailyAvgIncome,
                    ),
                  ),
                ],
              ),
              InfoCardWithDelta(
                title: "tabs.stats.intervalReport.averages.flow".t(context),
                autoSizeGroup: _averagesGroup,
                money: stats.dailyAvgFlow,
                previousMoney: stats.previousDailyAvgFlow,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Future<void> fetch() async {
    if (!mounted) return;
    setState(() {
      busy = true;
    });

    // Powers the forecast + averages; isolated from the Sankey aggregation so a
    // failure on either side doesn't blank out the other.
    try {
      report = await FlowStandardReport.generate(range, rates);
    } catch (_) {
      report = null;
    }

    bool missing = false;
    bool error = false;

    try {
      final analytics = await ObjectBox().flowByCategories(range: range);

      // The initial fetch runs from initState (via the mixin), where reading
      // inherited widgets like Theme isn't allowed yet — so resolve theme
      // colors only after the await, once the element is mounted.
      if (!mounted) return;
      final Color otherColor = context.colorScheme.onSurface.withAlpha(0x66);
      final Color incomeColor = context.flowColors.income;
      final Color expenseColor = context.flowColors.expense;
      final Brightness brightness = Theme.of(context).brightness;
      final List<Color> incomePalette = sankeyIncomePalette(brightness);
      final List<Color> expensePalette = sankeyExpensePalette(brightness);

      final List<SankeyDatum> incomeNodes = [];
      final List<SankeyDatum> expenseNodes = [];
      final List<SankeyDatum> taxNodes = [];
      double income = 0.0;
      double expense = 0.0;

      for (final entry in analytics.flow.entries) {
        final flow = entry.value;
        final single = flow.merge(primaryCurrency, rates);
        missing = missing || single.hasMissingData;

        final Category? category = flow.associatedData;
        final String name =
            category?.name ?? "tabs.stats.analytics.uncategorized".tr();
        final bool isTax = categoryIsTax(category);

        final double incomeAmount = single.totalIncome.amount;
        final double expenseAmount = single.totalExpense.amount.abs();

        if (incomeAmount > 0) {
          incomeNodes.add(
            SankeyDatum(label: name, value: incomeAmount, color: otherColor),
          );
          income += incomeAmount;
        }
        if (expenseAmount > 0) {
          final SankeyDatum node = SankeyDatum(
            label: name,
            value: expenseAmount,
            color: otherColor,
          );
          if (isTax) {
            taxNodes.add(node);
          } else {
            expenseNodes.add(node);
          }
          expense += expenseAmount;
        }
      }

      layout = buildBudgetSankeyLayout(
        income: _bucket(
          incomeNodes,
          _maxIncomeNodes,
          otherColor,
          incomePalette,
        ),
        expenses: _bucket(
          expenseNodes,
          _maxExpenseNodes,
          otherColor,
          expensePalette,
        ),
        taxes: taxNodes,
        netColor: sankeyNetColor(brightness),
        surplusColor: incomeColor,
        deficitColor: expenseColor,
        taxColor: sankeyTaxColor(brightness),
        grossLabel: "tabs.stats.analytics.cashFlow.grossIncome".tr(),
        netLabel: "tabs.stats.analytics.cashFlow.netIncome".tr(),
        surplusLabel: "tabs.stats.analytics.saved".tr(),
        fromReservesLabel: "tabs.stats.analytics.cashFlow.fromReserves".tr(),
        taxesLabel: "tabs.stats.analytics.cashFlow.taxes".tr(),
      );
      totalIncome = income;
      totalExpense = expense;
      missingRates = missing;
    } catch (_) {
      // Aggregation should be resilient to bad data now, but never leave the
      // page silently showing zeros if something unexpected throws.
      error = true;
      layout = const BudgetSankeyLayout(left: [], right: []);
      totalIncome = 0.0;
      totalExpense = 0.0;
    } finally {
      busy = false;
      failed = error;
      if (mounted) setState(() {});
    }
  }

  /// Keeps the top [max] nodes by value and rolls the rest into "Other".
  ///
  /// Colors come from [palette] (largest first), not from category icons.
  /// "Other" stays [otherColor]. Surplus / "From reserves" / taxes are
  /// painted later with dedicated colors so they stay unique.
  List<SankeyDatum> _bucket(
    List<SankeyDatum> nodes,
    int max,
    Color otherColor,
    List<Color> palette,
  ) {
    final List<SankeyDatum> sorted = [...nodes]
      ..sort((a, b) => b.value.compareTo(a.value));

    final int kept = sorted.length <= max ? sorted.length : max - 1;
    final List<SankeyDatum> top = [
      for (int i = 0; i < kept; i++)
        SankeyDatum(
          label: sorted[i].label,
          value: sorted[i].value,
          color: palette[i % palette.length],
        ),
    ];

    if (sorted.length <= max) return top;

    final double otherSum = sorted
        .skip(max - 1)
        .fold(0.0, (sum, node) => sum + node.value);

    return [
      ...top,
      SankeyDatum(
        label: "tabs.stats.analytics.other".tr(),
        value: otherSum,
        color: otherColor,
      ),
    ];
  }
}
