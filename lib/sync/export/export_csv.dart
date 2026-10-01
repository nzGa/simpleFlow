import "package:csv/csv.dart";
import "package:spendly/data/transaction_filter.dart";
import "package:spendly/l10n/named_enum.dart";
import "package:spendly/services/transactions.dart";
import "package:spendly/sync/export/export_csv/header_v1.dart";
import "package:intl/intl.dart";
import "package:moment_dart/moment_dart.dart";

Future<String> generateCSVContent() async {
  final transactions = await TransactionsService().findMany(
    TransactionFilter.empty,
  );

  final headers = [
    CSVHeader.uuid.localizedName,
    CSVHeader.title.localizedName,
    CSVHeader.notes.localizedName,
    CSVHeader.amount.localizedName,
    CSVHeader.currency.localizedName,
    CSVHeader.account.localizedName,
    CSVHeader.accountUuid.localizedName,
    CSVHeader.category.localizedName,
    CSVHeader.categoryUuid.localizedName,
    CSVHeader.type.localizedName,
    CSVHeader.subtype.localizedName,
    CSVHeader.createdDate.localizedName,
    CSVHeader.transactionDate.localizedName,
    CSVHeader.transactionDateIso8601.localizedName,
    CSVHeader.latitude.localizedName,
    CSVHeader.longitude.localizedName,
    CSVHeader.extra.localizedName,
  ];

  final Map<String, int> numberOfDecimalsToKeep = {};

  final transformed =
      transactions
          .map(
            (e) => [
              e.uuid,
              e.title ?? "",
              e.description ?? "",
              e.amount.toStringAsFixed(
                numberOfDecimalsToKeep[e.currency] ??=
                    NumberFormat.currency(name: e.currency).decimalDigits ?? 2,
              ),
              e.currency,
              e.account.target?.name,
              e.account.target?.uuid,
              e.category.target?.name,
              e.category.target?.uuid,
              e.type.localizedName,
              e.transactionSubtype?.localizedName,
              e.createdDate.format(payload: "LLL", forceLocal: true),
              e.transactionDate.format(payload: "LLL", forceLocal: true),
              e.transactionDate.toUtc().toIso8601String(),
              e.extensions.geo?.latitude?.toString() ?? "",
              e.extensions.geo?.longitude?.toString() ?? "",
              e.extra,
            ],
          )
          .toList()
        ..insert(0, headers);

  return const ListToCsvConverter().convert(
    transformed,
    convertNullTo: "",
    eol: "\n",
  );
}
