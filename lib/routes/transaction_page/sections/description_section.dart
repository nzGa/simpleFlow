import "package:spendly/entity/transaction.dart";
import "package:spendly/l10n/extensions.dart";
import "package:spendly/routes/transaction_page/section.dart";
import "package:flutter/material.dart";

class DescriptionSection extends StatelessWidget {
  final String? value;
  final Function(String)? onChanged;
  final FocusNode? focusNode;

  const DescriptionSection({
    super.key,
    this.value,
    this.onChanged,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Section(
      title: "transaction.description".t(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: TextFormField(
          initialValue: value,
          focusNode: focusNode,
          maxLength: Transaction.maxDescriptionLength,
          minLines: 2,
          maxLines: 6,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: "transaction.description.add".t(context),
            counter: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
