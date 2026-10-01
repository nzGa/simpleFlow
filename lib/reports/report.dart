import "package:spendly/data/exchange_rates.dart";
import "package:spendly/data/multi_currency_flow.dart";
import "package:spendly/data/transaction_filter.dart";
import "package:spendly/data/transactions_filter/time_range.dart";
import "package:spendly/entity/transaction.dart";
import "package:spendly/services/transactions.dart";
import "package:moment_dart/moment_dart.dart";

abstract class FlowReport {
  final ExchangeRates? rates;
  final String primaryCurrency;

  const FlowReport({required this.rates, required this.primaryCurrency});

  bool get missingExchangeRates => rates == null;

  bool get showMissingExchangeRatesWarning;

  static Future<RangeData> prepareRangeData(TimeRange range) async {
    final List<Transaction> transactions = await TransactionsService().findMany(
      TransactionFilter(range: TransactionFilterTimeRange.fromTimeRange(range)),
    );

    return RangeData(range: range, transactions: transactions);
  }

  static Future<({RangeData current, RangeData? previous})>
  prepareRangeDataWithPrevious(TimeRange range) async {
    final TimeRange? previous = range is PageableRange ? range.last : null;

    final RangeData currentRangeData = await prepareRangeData(range);
    RangeData? previousRangeData;
    if (previous != null) {
      previousRangeData = await prepareRangeData(previous);
    }
    return (current: currentRangeData, previous: previousRangeData);
  }
}

class RangeData {
  final TimeRange range;
  final List<Transaction> transactions;

  late final MultiCurrencyFlow<RangeData> multiCurrencyFlow =
      MultiCurrencyFlow()..addAll(transactions.map((t) => t.money));

  static DurationUnit getOptimalUnit(TimeRange range) {
    final int days = (range.duration.inHours / 24).ceil();

    if (days <= 2) {
      return DurationUnit.hour;
    } else if (days <= 93) {
      return DurationUnit.day;
    } else if (days <= 915) {
      return DurationUnit.month;
    } else {
      return DurationUnit.year;
    }
  }

  static Duration getOptimalInterval(TimeRange range) {
    final DurationUnit unit = getOptimalUnit(range);
    return Duration(microseconds: unit.microseconds);
  }

  RangeData({required this.range, required this.transactions})
    : assert(transactions.every((t) => range.contains(t.transactionDate)));
}
