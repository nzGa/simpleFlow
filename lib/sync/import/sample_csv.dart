import "package:spendly/sync/exception.dart";
import "package:spendly/sync/import/import_csv.dart";
import "package:spendly/sync/model/csv/parsed_data.dart";
import "package:flutter/services.dart";

/// Bundled six-month sample CSV used by Profile → Load sample data.
const String sampleImportCsvAssetPath = "assets/sample_import.csv";

/// Account currencies for [sampleImportCsvAssetPath].
///
/// All sample accounts and movements use EUR.
const Map<String, String> sampleImportAccountCurrencies = {
  "Principal": "EUR",
  "Efectivo": "EUR",
  "Ahorros": "EUR",
  "Euros": "EUR",
};

/// Loads the bundled sample CSV and pre-assigns account currencies.
///
/// Does not write or erase any app data.
Future<ImportCSV> loadSampleImportCsv({AssetBundle? bundle}) async {
  final String raw = await (bundle ?? rootBundle).loadString(
    sampleImportCsvAssetPath,
  );
  final ImportCSV importer = ImportCSV(CSVParsedData.fromString(raw));

  for (final String name in importer.data.accountNames) {
    final String? currency = sampleImportAccountCurrencies[name];
    if (currency == null) {
      throw ImportException(
        "No sample currency mapped for account $name",
        l10nKey: "sync.import.pickCurrencies.incomplete",
      );
    }
    importer.accountCurrencies[name] = currency;
  }

  return importer;
}

/// Parses the bundled sample CSV, assigns currencies, and runs the same
/// replace-import pipeline as the CSV wizard.
Future<String?> importSampleCsv({AssetBundle? bundle}) async {
  final ImportCSV importer = await loadSampleImportCsv(bundle: bundle);
  return importer.execute();
}
