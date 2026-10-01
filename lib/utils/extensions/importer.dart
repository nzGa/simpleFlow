import "package:spendly/l10n/flow_localizations.dart";
import "package:spendly/sync/import/base.dart";
import "package:spendly/sync/import/external/ivy_wallet_csv.dart";
import "package:spendly/sync/import/import_csv.dart";
import "package:spendly/sync/import/import_v1.dart";
import "package:spendly/sync/import/import_v2.dart";
import "package:spendly/utils/utils.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

extension ImporterExtensions on Importer {
  void goToRelevantPage(BuildContext context, {bool setupMode = false}) {
    switch (this) {
      case ImportV1 importV1:
        context.pushReplacement(
          "/import/wizard/v1?setupMode=$setupMode",
          extra: importV1,
        );
        break;
      case ImportV2 importV2:
        context.pushReplacement(
          "/import/wizard/v2?setupMode=$setupMode",
          extra: importV2,
        );
        break;
      case ImportCSV importCSV:
        context.pushReplacement(
          "/import/wizard/csv?setupMode=$setupMode",
          extra: importCSV,
        );
        break;
      case IvyWalletCsvImporter ivyWalletCsvImporter:
        context.pushReplacement(
          "/import/wizard/external/ivy?setupMode=$setupMode",
          extra: ivyWalletCsvImporter,
        );
        break;
      default:
        context.showErrorToast(
          error: "error.sync.invalidBackupFile".t(context),
        );
        break;
    }
  }
}
