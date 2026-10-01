import "package:spendly/data/string_multi_filter.dart";
import "package:spendly/data/transaction_filter.dart";
import "package:spendly/data/transactions_filter/time_range.dart";
import "package:spendly/entity/account.dart";
import "package:spendly/entity/category.dart";
import "package:spendly/entity/transaction.dart";
import "package:spendly/entity/transaction_filter_preset.dart";
import "package:spendly/entity/transaction_tag.dart";
import "package:spendly/l10n/named_enum.dart";
import "package:spendly/objectbox.dart";
import "package:spendly/objectbox/actions.dart";
import "package:spendly/objectbox/objectbox.g.dart";
import "package:spendly/prefs/local_preferences.dart";
import "package:spendly/providers/accounts_provider.dart";
import "package:spendly/providers/categories_provider.dart";
import "package:spendly/providers/transaction_tags_provider.dart";
import "package:spendly/services/currency_registry.dart";
import "package:spendly/utils/optional.dart";
import "package:spendly/widgets/sheets/select_multi_currency_sheet.dart";
import "package:spendly/widgets/sheets/select_multi_transaction_type_sheet.dart";
import "package:spendly/widgets/transaction_filter_head.dart";
import "package:spendly/widgets/transaction_filter_head/create_filter_preset_sheet.dart";
import "package:spendly/widgets/transaction_filter_head/select_filter_preset_sheet.dart";
import "package:spendly/widgets/transaction_filter_head/select_group_range_sheet.dart";
import "package:spendly/widgets/transaction_filter_head/select_multi_account_sheet.dart";
import "package:spendly/widgets/transaction_filter_head/select_multi_category_sheet.dart";
import "package:spendly/widgets/transaction_filter_head/select_transaction_filter_time_range_sheet.dart";
import "package:spendly/widgets/transaction_filter_head/transaction_filter_chip.dart";
import "package:spendly/widgets/transaction_filter_head/transaction_search_sheet.dart";
import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:material_symbols_icons_flow/symbols.dart";

class DefaultTransactionsFilterHead extends StatefulWidget {
  final TransactionFilter current;
  final TransactionFilter defaultFilter;

  final EdgeInsets padding;

  final void Function(TransactionFilter) onChanged;

  const DefaultTransactionsFilterHead({
    super.key,
    required this.current,
    required this.onChanged,
    this.defaultFilter = TransactionFilter.empty,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  });

  @override
  State<DefaultTransactionsFilterHead> createState() =>
      _DefaultTransactionsFilterHeadState();
}

class _DefaultTransactionsFilterHeadState
    extends State<DefaultTransactionsFilterHead> {
  late TransactionFilter _filter;

  late bool showCurrencyFilterChip;

  TransactionFilter get filter => _filter;
  set filter(TransactionFilter value) {
    _filter = value;
    widget.onChanged(value);
  }

  @override
  void initState() {
    super.initState();
    _filter = widget.current;

    TransitiveLocalPreferences().usesMultipleCurrencies.addListener(
      _updateShowCurrencyFilterChip,
    );
    showCurrencyFilterChip = TransitiveLocalPreferences().usesMultipleCurrencies
        .get();
  }

  @override
  void didUpdateWidget(DefaultTransactionsFilterHead oldWidget) {
    if (oldWidget.current != widget.current) {
      _filter = widget.current;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    TransitiveLocalPreferences().usesNonPrimaryCurrency.removeListener(
      _updateShowCurrencyFilterChip,
    );
    super.dispose();
  }

  QueryBuilder<TransactionFilterPreset> transactionFilterPresetsQb() =>
      ObjectBox().box<TransactionFilterPreset>().query();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionFilterPreset>>(
      stream: transactionFilterPresetsQb()
          .watch(triggerImmediately: true)
          .map((event) => event.find()),
      builder: (context, transactionPresetsSnapshot) {
        {
          final int differentFieldCount = widget.defaultFilter
              .calculateDifferentFieldCount(_filter);

          final List<Account>? activeAccounts =
              AccountsProvider.of(context).ready
              ? AccountsProvider.of(context).activeAccounts
              : null;
          final List<Category>? categories =
              CategoriesProvider.of(context).ready
              ? CategoriesProvider.of(context).categories
              : null;
          final List<TransactionTag>? tags =
              TransactionTagsProvider.of(context).ready
              ? TransactionTagsProvider.of(context).tags
              : null;

          if (activeAccounts != null &&
              categories != null &&
              !_filter.validate(
                accounts: activeAccounts.map((account) => account.uuid).toSet(),
                categories: categories.map((category) => category.uuid).toSet(),
                tags: (tags ?? <TransactionTag>[])
                    .map((tag) => tag.uuid)
                    .toSet(),
              )) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              filter = widget.defaultFilter;
              if (mounted) {
                setState(() {});
              }
            });
          }

          return TransactionFilterHead(
            padding: widget.padding,
            filterChips: [
              if (transactionPresetsSnapshot.hasData)
                FilterChip(
                  showCheckmark: false,
                  label: Text(differentFieldCount.toString()),
                  selected: differentFieldCount > 0,
                  avatar: const Icon(Symbols.filter_list_rounded),
                  onSelected: (_) => _showFilterPresetSelectionSheet(
                    transactionPresetsSnapshot.requireData,
                  ),
                ),
              TransactionFilterChip<TransactionSearchData>(
                translationKey: "transactions.query.filter.keyword",
                avatar: const Icon(Symbols.search_rounded),
                onSelect: onSearch,
                defaultValue: widget.defaultFilter.searchData,
                value: _filter.searchData,
                highlightOverride: _filter.searchData.normalizedKeyword != null,
              ),
              TransactionFilterChip<TransactionFilterTimeRange>(
                translationKey: "transactions.query.filter.timeRange",
                avatar: const Icon(Symbols.history_rounded),
                onSelect: onSelectRange,
                defaultValue: widget.defaultFilter.range,
                value: _filter.range,
              ),
              if (activeAccounts != null)
                TransactionFilterChip<Set<Account>>(
                  translationKey: "transactions.query.filter.accounts",
                  avatar: const Icon(Symbols.wallet_rounded),
                  onSelect: onSelectAccounts,
                  defaultValue: widget.defaultFilter.accounts
                      ?.mappedFilter(activeAccounts, (account) => account.uuid)
                      .toSet(),
                  value: _filter.accounts
                      ?.mappedFilter(
                        AccountsProvider.of(context).activeAccounts,
                        (account) => account.uuid,
                      )
                      .nonNulls
                      .toSet(),
                ),
              if (categories != null)
                TransactionFilterChip<Set<Category>>(
                  translationKey: "transactions.query.filter.categories",
                  avatar: const Icon(Symbols.category_rounded),
                  onSelect: onSelectCategories,
                  defaultValue: widget.defaultFilter.categories
                      ?.mappedFilter(categories, (category) => category.uuid)
                      .toSet(),
                  value: _filter.categories
                      ?.mappedFilter(categories, (category) => category.uuid)
                      .toSet(),
                ),
              TransactionFilterChip<List<TransactionType>>(
                translationKey: "transactions.query.filter.transactionType",
                avatar: const Icon(Symbols.swap_horiz_rounded),
                onSelect: onSelectType,
                defaultValue: null,
                value: _filter.types?.isNotEmpty == true
                    ? _filter.types!
                    : null,
              ),
              if (showCurrencyFilterChip)
                TransactionFilterChip<List<String>>(
                  translationKey: "transactions.query.filter.currency",
                  avatar: const Icon(Symbols.universal_currency_alt_rounded),
                  onSelect: onSelectCurrency,
                  defaultValue: widget.defaultFilter.currencies,
                  value: _filter.currencies?.isNotEmpty == true
                      ? _filter.currencies
                      : null,
                ),
              TransactionFilterChip<TransactionGroupRange>(
                translationKey: "transactions.query.filter.groupBy",
                avatar: const Icon(Symbols.atr_rounded),
                onSelect: onSelectGroupBy,
                defaultValue: widget.defaultFilter.groupBy,
                value: _filter.groupBy,
              ),
            ],
          );
        }
      },
    );
  }

  void onSearch() async {
    final TransactionSearchData? searchData =
        await showModalBottomSheet<TransactionSearchData>(
          context: context,
          builder: (context) =>
              TransactionSearchSheet(searchData: filter.searchData),
          isScrollControlled: true,
        );

    if (searchData != null) {
      setState(() {
        filter = filter.copyWithOptional(searchData: searchData);
      });
    }
  }

  void onSelectAccounts() async {
    final List<Account>? allActiveAccounts = AccountsProvider.of(context).ready
        ? AccountsProvider.of(context).activeAccounts
        : null;

    final Optional<List<Account>>? accounts = await showModalBottomSheet(
      context: context,
      builder: (context) => SelectMultiAccountSheet(
        accounts: ObjectBox().getAccounts(),
        selectedUuids: filter.accounts?.filter(
          allActiveAccounts?.map((account) => account.uuid).toList() ?? [],
        ),
      ),
      isScrollControlled: true,
    );

    final StringMultiFilter? accountsFilterOverride = switch (accounts?.value) {
      List<Account> accountsList when accountsList.isNotEmpty =>
        StringMultiFilter.whitelist(
          accountsList.map((account) => account.uuid).toList(),
        ),
      List<Account>() => StringMultiFilter.keepEverything(),
      _ => null,
    };

    if (accountsFilterOverride != null) {
      setState(() {
        filter = filter.copyWithOptional(
          accounts: accountsFilterOverride == StringMultiFilter.keepEverything()
              ? Optional(null)
              : Optional(accountsFilterOverride),
        );
      });
    }
  }

  void onSelectCategories() async {
    final List<Category>? allCategories = CategoriesProvider.of(context).ready
        ? CategoriesProvider.of(context).categories
        : null;

    final Optional<List<Category>>? categories = await showModalBottomSheet(
      context: context,
      builder: (context) => SelectMultiCategorySheet(
        categories: ObjectBox().getCategories(),
        selectedUuids: filter.categories?.filter(
          allCategories?.map((category) => category.uuid).toList() ?? [],
        ),
      ),
      isScrollControlled: true,
    );

    final Optional<StringMultiFilter>? categoriesFilter = categories == null
        ? null
        : switch (categories.value) {
            List<Category> categoriesList => Optional<StringMultiFilter>(
              StringMultiFilter.whitelist(
                categoriesList.map((category) => category.uuid).toList(),
              ),
            ),
            null => Optional<StringMultiFilter>(null),
          };

    setState(() {
      filter = filter.copyWithOptional(categories: categoriesFilter);
    });
  }

  void onSelectType() async {
    final List<TransactionType>? types =
        await showModalBottomSheet<List<TransactionType>>(
          context: context,
          builder: (context) =>
              SelectMultiTransactionTypeSheet(currentlySelected: filter.types),
          isScrollControlled: true,
        );

    if (types != null) {
      setState(() {
        filter = filter.copyWithOptional(types: Optional(types));
      });
    }
  }

  void onSelectCurrency() async {
    final Set<String> possibleCurrencies = ObjectBox()
        .getAccounts()
        .map((account) => account.currency)
        .toSet();

    final List<String>? newCurrencies =
        await showModalBottomSheet<List<String>>(
          context: context,
          builder: (context) => SelectMultiCurrencySheet(
            currencies: possibleCurrencies
                .map(
                  (code) => CurrencyRegistryService().groupedCurrencies[code],
                )
                .nonNulls
                .toList(),
            currentlySelected: filter.currencies,
          ),
          isScrollControlled: true,
        );

    if (newCurrencies != null) {
      setState(() {
        filter = filter.copyWithOptional(currencies: Optional(newCurrencies));
      });
    }
  }

  void onSelectGroupBy() async {
    final TransactionGroupRange? newGroupBy =
        await showModalBottomSheet<TransactionGroupRange>(
          context: context,
          builder: (context) => SelectGroupRangeSheet(selected: filter.groupBy),
          isScrollControlled: true,
        );

    if (newGroupBy != null) {
      setState(() {
        filter = filter.copyWithOptional(groupBy: Optional(newGroupBy));
      });
    }
  }

  void onSelectRange() async {
    final TransactionFilterTimeRange? newTransactionFilterTimeRange =
        await showTransactionFilterTimeRangeSelectorSheet(
          context,
          initialValue: _filter.range,
        );

    if (!mounted || newTransactionFilterTimeRange == null) return;

    setState(() {
      filter = filter.copyWithOptional(
        range: Optional(newTransactionFilterTimeRange),
      );
    });
  }

  void _updateShowCurrencyFilterChip() {
    showCurrencyFilterChip = TransitiveLocalPreferences().usesMultipleCurrencies
        .get();
    if (!mounted) return;
    setState(() {});
  }

  void _saveNewFilterPreset() async {
    await showModalBottomSheet<int>(
      context: context,
      builder: (context) => CreateFilterPresetSheet(
        filter: _filter,
        initialName: _filter.range?.preset?.localizedNameContext(context),
      ),
      isScrollControlled: true,
    );
  }

  void _showFilterPresetSelectionSheet(
    List<TransactionFilterPreset> presets,
  ) async {
    final Optional<TransactionFilter>? selected =
        await showModalBottomSheet<Optional<TransactionFilter>>(
          context: context,
          builder: (context) => SelectFilterPresetSheet(
            selected: _filter,
            onSaveAsNew: _saveNewFilterPreset,
          ),
          isScrollControlled: true,
        );

    if (selected == null || selected.value == null) return;
    if (!mounted) return;

    setState(() {
      filter = selected.value!;
    });
  }
}
