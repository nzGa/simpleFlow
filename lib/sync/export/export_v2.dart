import "dart:convert";
import "dart:io";

import "package:archive/archive_io.dart";
import "package:spendly/constants.dart";
import "package:spendly/data/transaction_filter.dart";
import "package:spendly/entity/account.dart";
import "package:spendly/entity/budget.dart";
import "package:spendly/entity/category.dart";
import "package:spendly/entity/file_attachment.dart";
import "package:spendly/entity/profile.dart";
import "package:spendly/entity/recurring_transaction.dart";
import "package:spendly/entity/transaction.dart";
import "package:spendly/entity/transaction_filter_preset.dart";
import "package:spendly/entity/transaction_tag.dart";
import "package:spendly/entity/user_preferences.dart";
import "package:spendly/logging.dart";
import "package:spendly/objectbox.dart";
import "package:spendly/objectbox/objectbox.g.dart";
import "package:spendly/services/transactions.dart";
import "package:spendly/services/user_preferences.dart";
import "package:spendly/sync/export.dart";
import "package:spendly/sync/model/model_v2.dart";
import "package:spendly/utils/copy_directory.dart";
import "package:path/path.dart" as path;
import "package:uuid/uuid.dart";

Future<String> generateBackupJSONContentV2() async {
  const int versionCode = 2;
  syncLogger.fine("Initiating export, version code = $versionCode");

  final List<Transaction> transactions = await TransactionsService().findMany(
    TransactionFilter.all,
  );
  syncLogger.fine("Finished fetching transactions");

  final List<RecurringTransaction> recurringTransactions = await ObjectBox()
      .box<RecurringTransaction>()
      .getAllAsync();
  syncLogger.fine("Finished fetching recurring transactions");

  final List<Account> accounts = await ObjectBox().box<Account>().getAllAsync();
  syncLogger.fine("Finished fetching accounts");

  final List<Category> categories = await ObjectBox()
      .box<Category>()
      .getAllAsync();
  syncLogger.fine("Finished fetching categories");

  final List<TransactionTag> transactionTags = await ObjectBox()
      .box<TransactionTag>()
      .getAllAsync();
  syncLogger.fine("Finished fetching transaction tags");

  final List<FileAttachment> attachments = await ObjectBox()
      .box<FileAttachment>()
      .getAllAsync();
  syncLogger.fine("Finished fetching file attachments");

  final List<Budget> budgets = await ObjectBox().box<Budget>().getAllAsync();
  syncLogger.fine("Finished fetching budgets");

  final DateTime exportDate = DateTime.now().toUtc();

  final Query<Profile> firstProfileQuery = ObjectBox()
      .box<Profile>()
      .query()
      .build();

  final Profile? profile = firstProfileQuery.findFirst();

  final String username = profile?.name ?? "Default Profile";

  firstProfileQuery.close();

  final Query<UserPreferences> firstUserPreferencesQuery = ObjectBox()
      .box<UserPreferences>()
      .query()
      .build();

  final UserPreferences? userPreferences = firstUserPreferencesQuery
      .findFirst();

  firstUserPreferencesQuery.close();

  final Query<TransactionFilterPreset> firstTransactionFilterPresetQuery =
      ObjectBox().box<TransactionFilterPreset>().query().build();

  final List<TransactionFilterPreset> transactionFilterPresets =
      firstTransactionFilterPresetQuery.find();

  firstTransactionFilterPresetQuery.close();

  final SyncModelV2 obj = SyncModelV2(
    versionCode: versionCode,
    exportDate: exportDate,
    username: username,
    appVersion: appVersion,
    transactions: transactions,
    transactionTags: transactionTags,
    accounts: accounts,
    categories: categories,
    transactionFilterPresets: transactionFilterPresets,
    profile: profile,
    userPreferences: userPreferences,
    recurringTransactions: recurringTransactions,
    attachments: attachments,
    budgets: budgets,
    primaryCurrency:
        userPreferences?.primaryCurrency ??
        UserPreferencesService().primaryCurrency,
  );

  return jsonEncode(obj.toJson());
}

Future<File> generateBackupZipV2({Function(double)? onProgress}) async {
  final String jsonFileName = generateBackupFileName("json");
  final String zipFileName = generateBackupFileName("zip");

  final String jsonContent = await generateBackupJSONContentV2();

  final Directory tempDir = Directory(
    path.join(Directory.systemTemp.path, Uuid().v4()),
  )..createSync(recursive: true);

  await File(path.join(tempDir.path, jsonFileName)).writeAsString(jsonContent);

  final Directory imagesDir = Directory(
    path.join(tempDir.path, "assets", ObjectBox.imagesDirectoryName),
  );

  try {
    await imagesDir.create(recursive: true);

    final List<FileSystemEntity> filesList = Directory(
      ObjectBox.imagesDirectory,
    ).listSync(followLinks: false, recursive: false);
    final List<File> pngsList = filesList
        .where((file) => path.extension(file.path).toLowerCase() == ".png")
        .map((file) => File(file.path))
        .toList();

    await Future.wait(
      pngsList.map(
        (png) => png.copy(path.join(imagesDir.path, path.basename(png.path))),
      ),
    ).catchError((error) {
      syncLogger.warning(
        "Failed to copy some or all of the images to temp directory",
        error,
      );
      return <File>[];
    });
  } catch (e) {
    syncLogger.warning(
      "Failed to copy some or all of the images to temp directory",
      e,
    );
  }

  final Directory filesDir = Directory(
    path.join(tempDir.path, "assets", ObjectBox.filesDirectoryName),
  );

  try {
    await copyDirectory(Directory(ObjectBox.filesDirectory), filesDir);
  } catch (e) {
    syncLogger.warning("Failed to copy file attachments to temp directory", e);
  }

  final File result = File(path.join(Directory.systemTemp.path, zipFileName));

  final ZipFileEncoder encoder = ZipFileEncoder();
  await encoder.zipDirectory(
    tempDir,
    filename: result.path,
    onProgress: onProgress,
  );

  return result;
}
