import "package:spendly/data/multi_currency_flow.dart";
import "package:spendly/entity/category.dart";
import "package:spendly/entity/transaction.dart";
import "package:spendly/reports/report.dart";
import "package:uuid/uuid.dart";

class CategoryFlowReport extends FlowReport {
  final List<Transaction> transactions;
  final List<Category> categories;

  /// Map of category UUID, [MultiCurrencyFlow]
  ///
  /// Uses [Namespace.nil] for uncategorized transactions
  final Map<String, MultiCurrencyFlow> data = {};

  bool _showMissingExchangeRatesWarning = false;

  @override
  bool get showMissingExchangeRatesWarning => _showMissingExchangeRatesWarning;

  CategoryFlowReport({
    required this.transactions,
    required this.categories,
    required super.rates,
    required super.primaryCurrency,
  }) {
    init();
  }

  void init() {
    bool hasNonPrimaryCurrency = false;

    final Map<String, Category> categoriesMap = {};

    for (final Category category in categories) {
      categoriesMap[category.uuid] = category;
    }

    for (final Transaction transaction in transactions) {
      if (transaction.currency != primaryCurrency) {
        hasNonPrimaryCurrency = true;
      }

      final String categoryUuid =
          transaction.categoryUuid ?? Namespace.nil.value;

      data[categoryUuid] ??= MultiCurrencyFlow();
      data[categoryUuid]!.add(transaction.money);
    }

    if (hasNonPrimaryCurrency && rates == null) {
      _showMissingExchangeRatesWarning = true;
    }
  }
}
