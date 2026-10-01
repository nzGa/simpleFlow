import "package:spendly/data/exchange_rates.dart";
import "package:spendly/data/money.dart";
import "package:spendly/data/single_currency_flow.dart";
import "package:spendly/services/currency_registry.dart";

/// A little class that sums expense/income separately for each currency.
///
/// See also [SingleCurrencyFlow] for a version that only works with
/// the primary currency.
class MultiCurrencyFlow<T> {
  final T? associatedData;

  final Map<String, double> _totalExpenseByCurrency = {};
  final Map<String, double> _totalIncomeByCurrency = {};

  int _expenseCount = 0;
  int get expenseCount => _expenseCount;
  int _incomeCount = 0;
  int get incomeCount => _incomeCount;

  Set<String> get uniqueCurrencies => {
    ..._totalExpenseByCurrency.keys,
    ..._totalIncomeByCurrency.keys,
  };

  MultiCurrencyFlow({this.associatedData});

  void add(Money money) {
    final double amount = money.amount;
    final String currency = money.currency.trim().toUpperCase();

    if (amount.abs() == 0.0) {
      return;
    }

    if (!CurrencyRegistryService().isCurrencyCodeValid(currency)) {
      throw FormatException(
        "[MoneyFlow] Failed adding income, invalid currency code: $currency",
      );
    }

    if (amount.isNegative) {
      _totalExpenseByCurrency.update(
        currency,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
      _expenseCount++;
    } else {
      _totalIncomeByCurrency.update(
        currency,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
      _incomeCount++;
    }
  }

  void addAll(Iterable<Money> moneys) => moneys.forEach(add);

  /// Returns the expense for the given currency, excludes other currency expenses
  Money getExpenseByCurrency(String currency) {
    return Money(_totalExpenseByCurrency[currency] ?? 0.0, currency);
  }

  /// Returns the income for the given currency, excludes other currency incomes
  Money getIncomeByCurrency(String currency) {
    return Money(_totalIncomeByCurrency[currency] ?? 0.0, currency);
  }

  Money getFlowByCurrency(String currency) {
    return getIncomeByCurrency(currency) + getExpenseByCurrency(currency);
  }

  SingleCurrencyFlow<T> merge(String currency, ExchangeRates? rates) {
    return SingleCurrencyFlow(
        currency: currency,
        associatedData: associatedData,
      )
      ..addAll(
        _totalIncomeByCurrency.entries.map(
          (entry) => Money(entry.value, entry.key),
        ),
        rates,
      )
      ..addAll(
        _totalExpenseByCurrency.entries.map(
          (entry) => Money(entry.value, entry.key),
        ),
        rates,
      );
  }
}
