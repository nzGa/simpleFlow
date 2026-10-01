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
import "package:spendly/sync/model/base.dart";
import "package:json_annotation/json_annotation.dart";

part "model_v2.g.dart";

@JsonSerializable()
class SyncModelV2 extends SyncModelBase {
  final List<Account> accounts;
  final List<Category> categories;
  final List<Transaction> transactions;
  final List<RecurringTransaction>? recurringTransactions;
  final List<TransactionFilterPreset>? transactionFilterPresets;
  final List<TransactionTag>? transactionTags;
  final List<FileAttachment>? attachments;

  /// Backups made before budgets existed lack this field.
  final List<Budget>? budgets;
  final Profile? profile;
  final UserPreferences? userPreferences;
  final String? primaryCurrency;

  const SyncModelV2({
    required super.versionCode,
    required super.exportDate,
    required super.username,
    required super.appVersion,
    required this.transactions,
    required this.recurringTransactions,
    required this.accounts,
    required this.categories,
    required this.transactionFilterPresets,
    required this.transactionTags,
    required this.attachments,
    required this.budgets,
    required this.profile,
    required this.userPreferences,
    required this.primaryCurrency,
  });

  factory SyncModelV2.fromJson(Map<String, dynamic> json) =>
      _$SyncModelV2FromJson(json);
  Map<String, dynamic> toJson() => _$SyncModelV2ToJson(this);
}
