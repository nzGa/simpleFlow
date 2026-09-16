import "package:flow/data/setup/default_categories.dart";
import "package:flow/providers/categories_provider.dart";
import "package:flow/entity/category.dart";
import "package:flow/entity/transaction/type.dart";
import "package:flow/l10n/extensions.dart";
import "package:flow/utils/optional.dart";
import "package:flow/utils/simple_query_sorter.dart";
import "package:flow/widgets/general/directional_chevron.dart";
import "package:flow/widgets/general/flow_icon.dart";
import "package:flow/widgets/general/frame.dart";
import "package:flow/widgets/general/modal_overflow_bar.dart";
import "package:flow/widgets/general/modal_sheet.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:material_symbols_icons_flow/symbols.dart";

/// Pops with [ValueOr<Category>]
class SelectCategorySheet extends StatefulWidget {
  final int? currentlySelectedCategoryId;

  /// Defaults to [true] when there are more than 6 categories.
  final bool? showSearchBar;

  final bool showTrailing;

  /// When set, only matching income or expense categories are listed.
  /// Null shows every category (bulk edits of mixed types).
  final TransactionType? transactionType;

  const SelectCategorySheet({
    super.key,
    this.currentlySelectedCategoryId,
    this.showSearchBar,
    this.showTrailing = true,
    this.transactionType,
  });

  @override
  State<SelectCategorySheet> createState() => _SelectCategorySheetState();
}

class _SelectCategorySheetState extends State<SelectCategorySheet> {
  String _query = "";

  @override
  Widget build(BuildContext context) {
    List<Category> categories = CategoriesProvider.of(
      context,
    ).categoriesFor(widget.transactionType);
    if (widget.transactionType == TransactionType.income) {
      categories = pinPaycheckCategory(
        categories,
        localizedPaycheckName: "setup.categories.preset.paychecks".t(context),
      );
    }
    final bool showSearchBar = widget.showSearchBar ?? categories.length > 6;
    final List<Category> results = simpleSortByQuery(categories, _query);
    final String titleKey = widget.transactionType == TransactionType.income
        ? "transaction.edit.selectCategory.income"
        : "transaction.edit.selectCategory";

    return ModalSheet.scrollable(
      title: Text(titleKey.t(context)),
      trailing: ModalOverflowBar(
        alignment: .end,
        children: [
          TextButton.icon(
            onPressed: () => context.push(
              "/category/new",
              extra: widget.transactionType == TransactionType.income,
            ),
            icon: const Icon(Symbols.add_rounded),
            label: Text("general.new".t(context)),
          ),
          TextButton.icon(
            onPressed: () => context.pop(const Optional<Category>(null)),
            icon: const Icon(Symbols.block_rounded, fill: 0.0),
            label: Text("category.skip".t(context)),
          ),
        ],
      ),
      leading: showSearchBar
          ? Frame(
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: "general.search".t(context),
                  prefixIcon: const Icon(Symbols.search_rounded),
                ),
              ),
            )
          : null,
      child: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...results.map(
                (category) => ListTile(
                  key: ValueKey(category.uuid),
                  title: Text(category.name),
                  leading: FlowIcon(
                    category.icon,
                    colorScheme: category.colorScheme,
                  ),
                  trailing: widget.showTrailing ? LeChevron() : null,
                  onTap: () => context.pop(Optional(category)),
                  selected: widget.currentlySelectedCategoryId == category.id,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
