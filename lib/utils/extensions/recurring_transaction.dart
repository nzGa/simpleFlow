import "package:spendly/entity/recurring_transaction.dart";
import "package:spendly/entity/transaction/extensions/default/recurring.dart";

extension RecurringTransactionHelpers on RecurringTransaction {
  String get extensionIdentifierTag => Recurring(
    uuid: uuid,
    initialTransactionDate: DateTime.now(),
  ).extensionIdentifierTag;
}
