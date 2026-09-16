import "dart:io";

import "package:flow/data/setup/default_categories.dart";
import "package:flow/sync/import/sample_csv.dart";
import "package:flow/sync/model/csv/parsed_data.dart";
import "package:flow/sync/model/csv/parsers.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("A valid csv", () async {
    final valid = await CSVParsedData.fromFile(
      File("test/import/valid-1.csv"),
    ).then((v) => v as CSVParsedData?).catchError((e) => null);

    expect(valid, isNotNull);
    expect(valid?.accountNames.length, 3);
    expect(valid?.categoryNames.nonNulls.length, 24);
    expect(valid?.transactions.length, 81);
  });
  test("An invalid csv", () async {
    final invalid = await CSVParsedData.fromFile(
      File("test/import/invalid-1.csv"),
    ).then((e) => e as dynamic).catchError((e) => e);

    expect(invalid, CSVCellParserError.invalidDate);
  });
  test("Sample six-month import csv", () {
    final sample = CSVParsedData.fromString(
      File("assets/sample_import.csv").readAsStringSync(),
    );

    expect(sample.accountNames, {
      "Principal",
      "Efectivo",
      "Ahorros",
      "Dólares",
    });
    expect(
      sample.accountNames.every(sampleImportAccountCurrencies.containsKey),
      isTrue,
    );
    expect(sample.transactions.length, greaterThan(400));
    expect(sample.categoryNames.nonNulls.length, greaterThanOrEqualTo(15));

    final dates = sample.transactions.map((t) => t.transactionDate).toList();
    expect(
      dates.every(
        (d) =>
            !d.isBefore(DateTime(2026, 3, 14)) &&
            !d.isAfter(DateTime(2026, 9, 14, 23, 59, 59)),
      ),
      isTrue,
    );
    expect(sample.transactions.any((t) => t.amount < 0), isTrue);

    const transferOrOpening = {
      "Saldo inicial",
      "Extracción efectivo",
      "Extracción cajero",
      "Ahorro mensual",
    };
    final incomes = sample.transactions.where(
      (t) => t.amount > 0 && !transferOrOpening.contains(t.title),
    );
    expect(incomes.length, greaterThanOrEqualTo(30));
    expect(incomes.any((t) => t.title == "Sueldo"), isTrue);
    expect(incomes.every((t) => t.category == "Nómina"), isTrue);

    final positiveCategorized = sample.transactions.where(
      (t) => t.amount > 0 && (t.category ?? "").isNotEmpty,
    );
    expect(positiveCategorized.every((t) => t.category == "Nómina"), isTrue);
    expect(positiveCategorized.any((t) => t.category == "Servicios"), isFalse);
    expect(sample.transactions.any((t) => t.category == "Ahorrado"), isFalse);
    expect(sample.categoryNames.contains("Ahorrado"), isFalse);
    expect(
      sample.transactions
          .where((t) => t.amount < 0)
          .any((t) => t.category == "Nómina" || t.category == "Ahorrado"),
      isFalse,
    );
    expect(sample.categoryNames.nonNulls.where(isIncomeCategoryName).toSet(), {
      "Nómina",
    });
  });
}
