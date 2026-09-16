import "package:flow/entity/transaction.dart";
import "package:flow/l10n/extensions.dart";
import "package:flow/objectbox.dart";
import "package:flow/objectbox/actions.dart";
import "package:flow/theme/theme.dart";
import "package:flow/widgets/general/frame.dart";
import "package:flutter/material.dart";

class TitleInput extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController controller;

  final int? selectedAccountId;
  final int? selectedCategoryId;
  final TransactionType transactionType;

  final double? amount;
  final String? currency;
  final DateTime? transactionDate;

  final String fallbackTitle;

  final Function(String) onSubmitted;

  const TitleInput({
    super.key,
    required this.focusNode,
    required this.controller,
    this.selectedAccountId,
    this.selectedCategoryId,
    this.amount,
    this.currency,
    this.transactionDate,
    required this.transactionType,
    required this.fallbackTitle,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Frame(
      child: Autocomplete<RelevanceScoredTitle>(
        focusNode: focusNode,
        textEditingController: controller,
        optionsBuilder: (value) => getAutocompleteOptions(value.text),
        displayStringForOption: (option) => option.title,
        onSelected: (option) {
          controller.text = option.title;
        },
        optionsViewBuilder: (context, onSelected, options) => Material(
          color: context.colorScheme.surface,
          elevation: 4.0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8.0),
              bottomRight: Radius.circular(8.0),
            ),
            side: BorderSide(color: context.flowColors.semi),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in options)
                  ListTile(
                    title: Text(item.title),
                    onTap: () => onSelected(item),
                  ),
              ],
            ),
          ),
        ),
        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) =>
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: context.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                  maxLength: Transaction.maxTitleLength,
                  onSubmitted: onSubmitted,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: fallbackTitle,
                    hintStyle: context.textTheme.headlineMedium?.copyWith(
                      color: context.textTheme.headlineMedium?.color?.withAlpha(
                        0x80,
                      ),
                    ),
                    border: UnderlineInputBorder(),
                    counter: const SizedBox.shrink(),
                  ),
                ),
      ),
    );
  }

  Future<List<RelevanceScoredTitle>> getAutocompleteOptions(String query) =>
      ObjectBox()
          .transactionTitleSuggestions(
            currentInput: query,
            accountId: selectedAccountId,
            categoryId: selectedCategoryId,
            type: transactionType,
            amount: amount,
            currency: currency,
            transactionDate: transactionDate,
            limit: 5,
          )
          .then(
            (results) => results
                .where((item) => item.title != "transaction.fallbackTitle".tr())
                .toList(),
          );
}
