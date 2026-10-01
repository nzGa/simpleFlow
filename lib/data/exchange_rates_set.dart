import "package:spendly/data/exchange_rates.dart";
import "package:spendly/services/currency_registry.dart";

class ExchangeRatesSet {
  final Map<String, ExchangeRates> rates;

  ExchangeRatesSet(this.rates);

  void set(String baseCurrency, ExchangeRates exchangeRates) {
    if (!CurrencyRegistryService().isCurrencyCodeValid(baseCurrency)) {
      throw ArgumentError("Invalid currency code: $baseCurrency");
    }

    rates[baseCurrency] = exchangeRates;
  }

  ExchangeRates? get(String baseCurrency) {
    if (!CurrencyRegistryService().isCurrencyCodeValid(baseCurrency)) {
      throw ArgumentError("Invalid currency code: $baseCurrency");
    }

    return rates[baseCurrency];
  }

  factory ExchangeRatesSet.fromJson(Map json) {
    final Map<String, ExchangeRates> rates = {};

    for (final String baseCurrency in json.keys) {
      rates[baseCurrency] = ExchangeRates.fromJson(json[baseCurrency]);
    }

    return ExchangeRatesSet(rates);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    for (final MapEntry<String, ExchangeRates> entry in rates.entries) {
      json[entry.key] = entry.value.toJson();
    }

    return json;
  }
}
