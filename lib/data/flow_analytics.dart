import "package:spendly/data/multi_currency_flow.dart";
import "package:moment_dart/moment_dart.dart";

class FlowAnalytics<T> {
  final TimeRange range;

  final Map<String, MultiCurrencyFlow<T>> flow;

  const FlowAnalytics({required this.range, required this.flow});
}
