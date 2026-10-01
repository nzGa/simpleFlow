import "dart:convert";

import "package:spendly/constants.dart";
import "package:spendly/data/transaction_filter.dart";
import "package:spendly/entity/account.dart";
import "package:spendly/entity/category.dart";
import "package:spendly/entity/profile.dart";
import "package:spendly/entity/transaction.dart";
import "package:spendly/logging.dart";
import "package:spendly/objectbox.dart";
import "package:spendly/objectbox/objectbox.g.dart";
import "package:spendly/services/transactions.dart";
import "package:spendly/sync/model/model_v1.dart";

Future<String> generateBackupContentV1() async {
  const int versionCode = 1;
  syncLogger.fine("Initiating export, version code = $versionCode");

  final List<Transaction> transactions = await TransactionsService().findMany(
    TransactionFilter.all,
  );
  syncLogger.fine("Finished fetching transactions");

  final List<Account> accounts = await ObjectBox().box<Account>().getAllAsync();
  syncLogger.fine("Finished fetching accounts");

  final List<Category> categories = await ObjectBox()
      .box<Category>()
      .getAllAsync();
  syncLogger.fine("Finished fetching categories");

  final DateTime exportDate = DateTime.now().toUtc();

  final Query<Profile> firstProfileQuery = ObjectBox()
      .box<Profile>()
      .query()
      .build();

  final String username =
      firstProfileQuery.findFirst()?.name ?? "Default Profile";

  firstProfileQuery.close();

  final SyncModelV1 obj = SyncModelV1(
    versionCode: versionCode,
    exportDate: exportDate,
    username: username,
    appVersion: appVersion,
    transactions: transactions,
    accounts: accounts,
    categories: categories,
  );

  return jsonEncode(obj.toJson());
}
