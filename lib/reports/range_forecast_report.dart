import "package:spendly/data/money.dart";
import "package:spendly/data/single_currency_flow.dart";
import "package:spendly/objectbox/actions.dart";
import "package:spendly/reports/report.dart";
import "package:moment_dart/moment_dart.dart";

class RangeForecastReport extends FlowReport {
  final RangeData previousRangeData;

  /// The duration doesn't have to same as the previous range,
  /// and it will be aligned to the end of the previous range.
  final RangeData currentRangeData;

  TimeRange? calculateCurrentTransactionsSpannedRange() => currentRangeData
      .transactions
      .where(
        (transaction) =>
            transaction.isPending != true &&
            !transaction.transactionDate.isFutureAnchored(
              DateTime.now().startOfNextMinute(),
            ),
      )
      .range;

  final SingleCurrencyFlow forecast = SingleCurrencyFlow();

  bool _showMissingExchangeRatesWarning = false;

  RangeForecastReport({
    required super.rates,
    required super.primaryCurrency,
    required this.previousRangeData,
    required this.currentRangeData,
  }) {
    _init();
  }

  void _init() {
    if (previousRangeData.transactions.isEmpty) {
      throw StateError("Previous transactions cannot be empty");
    }

    bool hasNonPrimaryCurrency = false;

    final TimeRange? currentSpannedRange =
        calculateCurrentTransactionsSpannedRange();

    if (previousRangeData.multiCurrencyFlow.uniqueCurrencies.any(
      (currency) => currency != primaryCurrency,
    )) {
      hasNonPrimaryCurrency = true;
    }

    if (!hasNonPrimaryCurrency &&
        currentRangeData.multiCurrencyFlow.uniqueCurrencies.any(
          (currency) => currency != primaryCurrency,
        )) {
      hasNonPrimaryCurrency = true;
    }

    if (hasNonPrimaryCurrency && rates == null) {
      _showMissingExchangeRatesWarning = true;
    }

    if (currentSpannedRange == null) {
      return;
    }

    final SingleCurrencyFlow previousMergedFlow = previousRangeData
        .multiCurrencyFlow
        .merge(primaryCurrency, rates);
    final SingleCurrencyFlow currentMergedFlow = currentRangeData
        .multiCurrencyFlow
        .merge(primaryCurrency, rates);

    final double previousExpensePerSecond =
        (previousMergedFlow.totalExpense.amount +
            currentMergedFlow.totalExpense.amount) /
        (previousRangeData.range.duration.inSeconds +
            currentSpannedRange.duration.inSeconds);
    final double previousIncomePerSecond =
        (previousMergedFlow.totalIncome.amount +
            currentMergedFlow.totalIncome.amount) /
        (previousRangeData.range.duration.inSeconds +
            currentSpannedRange.duration.inSeconds);

    final Duration remainingCurrentRange = currentRangeData.range.to.difference(
      currentSpannedRange.to,
    );

    if (remainingCurrentRange.isNegative) {
      throw StateError("Invalid state. Remaining duration is less than zero.");
    }

    forecast.addAll([
      Money(
        currentMergedFlow.totalIncome.amount +
            (previousIncomePerSecond * remainingCurrentRange.inSeconds),
        primaryCurrency,
      ),
      Money(
        currentMergedFlow.totalExpense.amount +
            (previousExpensePerSecond * remainingCurrentRange.inSeconds),
        primaryCurrency,
      ),
    ], rates);
  }

  @override
  bool get showMissingExchangeRatesWarning => _showMissingExchangeRatesWarning;
}
