import "package:flow/data/exchange_rates.dart";
import "package:flow/data/money.dart";
import "package:flow/data/setup/default_categories.dart";
import "package:flow/data/transaction_programmable_object.dart";
import "package:flow/entity/account.dart";
import "package:flow/entity/category.dart";
import "package:flow/entity/file_attachment.dart";
import "package:flow/entity/recurring_transaction.dart";
import "package:flow/entity/transaction.dart";
import "package:flow/entity/transaction/extensions/base.dart";
import "package:flow/entity/transaction/extensions/default/geo.dart";
import "package:flow/entity/transaction/extensions/default/recurring.dart";
import "package:flow/entity/transaction/wrapper.dart";
import "package:flow/entity/transaction_tag.dart";
import "package:flow/entity/user_preferences/transaction_entry_flow.dart";
import "package:flow/l10n/extensions.dart";
import "package:flow/l10n/named_enum.dart";
import "package:flow/objectbox.dart";
import "package:flow/objectbox/actions.dart";
import "package:flow/prefs/local_preferences.dart";
import "package:flow/providers/accounts_provider.dart";
import "package:flow/providers/categories_provider.dart";
import "package:flow/routes/transaction_page/input_amount_sheet.dart";
import "package:flow/routes/transaction_page/section.dart";
import "package:flow/routes/transaction_page/sections/description_section.dart";
import "package:flow/routes/transaction_page/select_recurrence.dart";
import "package:flow/routes/transaction_page/select_recurrence_sheet.dart";
import "package:flow/routes/transaction_page/select_recurring_update_mode_sheet.dart";
import "package:flow/routes/transaction_page/title_input.dart";
import "package:flow/services/accounts.dart";
import "package:flow/services/exchange_rates.dart";
import "package:flow/services/file_attachment.dart";
import "package:flow/services/recurring_transactions.dart";
import "package:flow/services/transactions.dart";
import "package:flow/services/user_preferences.dart";
import "package:flow/theme/theme.dart";
import "package:flow/utils/utils.dart";
import "package:flow/widgets/general/directional_chevron.dart";
import "package:flow/widgets/general/flow_icon.dart";
import "package:flow/widgets/general/form_close_button.dart";
import "package:flow/widgets/general/money_text.dart";
import "package:flow/widgets/sheets/select_account_sheet.dart";
import "package:flow/widgets/sheets/select_category_sheet.dart";
import "package:flow/widgets/transaction/imported_from_siri.dart";
import "package:flow/widgets/transaction/type_selector.dart";
import "package:flutter/foundation.dart" hide Category;
import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:flutter/services.dart";
import "package:go_router/go_router.dart";
import "package:logging/logging.dart";
import "package:material_symbols_icons_flow/symbols.dart";
import "package:moment_dart/moment_dart.dart";
import "package:recurrence/recurrence.dart";
import "package:uuid/uuid.dart";

final Logger _log = Logger("TransactionPage");

class TransactionPage extends StatefulWidget {
  /// Transaction Object ID
  final int transactionId;

  final TransactionProgrammableObject? params;

  bool get isNewTransaction => transactionId == 0;

  const TransactionPage.create({super.key, this.params}) : transactionId = 0;
  const TransactionPage.edit({super.key, required this.transactionId})
    : params = null;

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  late TransactionType _transactionType;

  bool get isTransfer => _transactionType == TransactionType.transfer;

  bool get _isIncome => _transactionType == TransactionType.income;

  String get _categorySectionTitleKey =>
      _isIncome ? "category.income" : "category";

  String get _categoryPickerTitleKey => _isIncome
      ? "transaction.edit.selectCategory.income"
      : "transaction.edit.selectCategory";

  late final TextEditingController _titleController;
  String? _descriptionMarkdown;
  late double _amount;

  double _conversionRate = 1.0;

  late final Transaction? _currentlyEditing;

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _selectAccountFocusNode = FocusNode();
  final FocusNode _selectAccountTransferToFocusNode = FocusNode();

  Geo? _geo;

  dynamic error;

  Account? _selectedAccount;
  Category? _selectedCategory;

  Account? _selectedAccountTransferTo;

  List<TransactionTag>? _selectedTags;

  List<FileAttachment>? _attachments;

  List<RelevanceScoredTitle>? autofillHints;

  RecurringTransaction? _recurringTransaction;

  Recurrence? _recurrence;

  DateTime? _transactionDate;

  DateTime get transactionDate => _transactionDate ?? DateTime.now();

  DateTime? _initialTransactionDate;

  /// Auto-applied primary account; not treated as a user edit on cancel.
  String? _initialAccountUuid;

  bool get pastDuePending => widget.isNewTransaction
      ? false
      : (_isPending && transactionDate.isPastAnchored());

  bool get crossCurrencyTransfer =>
      isTransfer &&
      _selectedAccount != null &&
      _selectedAccountTransferTo != null &&
      _selectedAccount!.currency != _selectedAccountTransferTo!.currency;

  bool _isPending = false;

  @override
  void initState() {
    super.initState();

    final accounts = ObjectBox().getAccounts();
    final categories = ObjectBox().getCategories();
    final transactionEntryFlow = UserPreferencesService().transactionEntryFlow;

    if (widget.isNewTransaction) {
      _currentlyEditing = null;
      _titleController = TextEditingController(
        text: widget.params?.title ?? "",
      );
      _descriptionMarkdown = widget.params?.notes;
      _selectedAccount = widget.params?.fromAccountUuid == null
          ? null
          : accounts.firstWhereOrNull(
              (account) => account.uuid == widget.params!.fromAccountUuid,
            );
      _selectedCategory = widget.params?.categoryUuid == null
          ? null
          : categories.firstWhereOrNull(
              (category) => category.uuid == widget.params!.categoryUuid,
            );
      _transactionDate = widget.params?.transactionDate ?? DateTime.now();
      _initialTransactionDate =
          widget.params?.transactionDate ?? DateTime.now();
      _transactionType = widget.params?.type ?? TransactionType.expense;
      _amount = switch (_transactionType) {
        .transfer => widget.params?.amount?.abs() ?? 0.0,
        .expense => -(widget.params?.amount ?? 0.0),
        .income => widget.params?.amount?.abs() ?? 0.0,
      };
      _selectedAccountTransferTo = widget.params?.toAccountUuid == null
          ? null
          : accounts.firstWhereOrNull(
              (account) => account.uuid == widget.params!.toAccountUuid,
            );
      _isPending = widget.params?.isPending ?? _isPending;
      if (_transactionType == TransactionType.transfer) {
        _conversionRate = widget.params?.transferConversionRate ?? 1.0;
      }

      if (_selectedAccount == null) {
        _applyPrimaryAccount();
      }
    } else {
      /// Transaction we're editing.
      _currentlyEditing = widget.isNewTransaction
          ? null
          : TransactionsService()
                .getOneSync(widget.transactionId)
                ?.findTransferOriginalOrThis();
      if (_currentlyEditing == null) {
        error = "Transaction with id ${widget.transactionId} was not found";
      } else {
        _titleController = TextEditingController(
          text: _currentlyEditing.title ?? "",
        );
        _descriptionMarkdown = _currentlyEditing.description;
        _selectedAccount = _currentlyEditing.account.target;
        _selectedCategory = _currentlyEditing.category.target;
        _selectedTags = _currentlyEditing.tags;
        _attachments = _currentlyEditing.attachments.toList();
        _transactionDate = _currentlyEditing.transactionDate;
        _initialTransactionDate = _currentlyEditing.transactionDate;
        _transactionType = _currentlyEditing.type;
        _amount = _currentlyEditing.isTransfer == true
            ? _currentlyEditing.amount.abs()
            : _currentlyEditing.amount;
        _selectedAccountTransferTo = accounts.firstWhereOrNull(
          (account) =>
              account.uuid ==
              _currentlyEditing.extensions.transfer?.toAccountUuid,
        );
        _geo = _currentlyEditing.extensions.geo;
        _isPending = _currentlyEditing.isPending ?? _isPending;
        if (_currentlyEditing.isTransfer == true) {
          _conversionRate =
              _currentlyEditing.extensions.transfer?.conversionRate ?? 1.0;
        }

        if (_currentlyEditing.isRecurring) {
          _recurringTransaction = RecurringTransactionsService().findOneSync(
            _currentlyEditing.extensions.recurring?.uuid,
          );
          _recurrence = _recurringTransaction?.recurrence;
        }
      }
    }

    _initialAccountUuid = _selectedAccount?.uuid;

    if (widget.isNewTransaction) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        _orchestrateFlow(transactionEntryFlow);
      });
    }
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _selectAccountFocusNode.dispose();
    _selectAccountTransferToFocusNode.dispose();

    _titleController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String primaryCurrency = UserPreferencesService().primaryCurrency;

    final TimeRange? startBounds = getStartBounds();

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (!hasChanged()) {
              pop();
            } else {
              HapticFeedback.mediumImpact();
            }
          },
          osSingleActivator(LogicalKeyboardKey.enter): () => save(),
          osSingleActivator(LogicalKeyboardKey.numpadEnter): () => save(),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              leadingWidth: 40.0,
              leading: FormCloseButton(
                canPop: () => !hasChanged(),
                onClose: pop,
              ),
              actions: [
                IconButton(
                  onPressed: () => save(),
                  icon: const Icon(Symbols.check_rounded),
                  tooltip: "general.save".t(context),
                ),
              ],
              actionsPadding: EdgeInsets.zero,
              title: TypeSelector(
                current: _transactionType,
                onChange: updateTransactionType,
                canEdit:
                    _currentlyEditing == null ||
                    _currentlyEditing.isTransfer == false,
              ),
              titleTextStyle: context.textTheme.bodyLarge,
              centerTitle: true,
              backgroundColor: context.colorScheme.surface,
            ),
            body: SingleChildScrollView(
              padding: EdgeInsetsGeometry.symmetric(vertical: 24.0),
              child: SafeArea(
                child: Form(
                  canPop: !hasChanged(),
                  child: Column(
                    spacing: 24.0,
                    children: [
                      TitleInput(
                        key: ValueKey(_amount),
                        focusNode: _titleFocusNode,
                        controller: _titleController,
                        transactionType: _transactionType,
                        selectedAccountId: _selectedAccount?.id,
                        selectedCategoryId: _selectedCategory?.id,
                        amount: _amount,
                        currency: _selectedAccount?.currency,
                        transactionDate: _transactionDate,
                        fallbackTitle: fallbackTitle,
                        onSubmitted: (_) => save(),
                      ),
                      Center(
                        child: InkWell(
                          onTap: inputAmount,
                          child: Center(
                            child: Text(
                              Money(
                                _amount,
                                _selectedAccount?.currency ?? primaryCurrency,
                              ).formatMoney(),
                              style: context.textTheme.displayMedium,
                            ),
                          ),
                        ),
                      ),
                      // From account
                      Section(
                        title: isTransfer
                            ? "transaction.transfer.from".t(context)
                            : "account".t(context),
                        child: ListTile(
                          leading: _selectedAccount == null
                              ? null
                              : FlowIcon(_selectedAccount!.icon, plated: true),
                          title: Text(
                            _selectedAccount?.name ??
                                "transaction.edit.selectAccount".t(context),
                          ),
                          subtitle:
                              (!widget.isNewTransaction &&
                                  _selectedAccount != null)
                              ? MoneyText(
                                  _selectedAccount!.balanceAt(transactionDate),
                                )
                              : null,
                          onTap: () => selectAccount(),
                          trailing: _selectedAccount == null
                              ? const Icon(Symbols.chevron_right)
                              : null,
                          focusNode: _selectAccountFocusNode,
                        ),
                      ),
                      // To account
                      if (isTransfer) ...[
                        Section(
                          title: "transaction.transfer.to".t(context),
                          child: ListTile(
                            leading: _selectedAccountTransferTo == null
                                ? null
                                : FlowIcon(
                                    _selectedAccountTransferTo!.icon,
                                    plated: true,
                                  ),
                            title: Text(
                              _selectedAccountTransferTo?.name ??
                                  "transaction.edit.selectAccount".t(context),
                            ),
                            subtitle:
                                (!widget.isNewTransaction &&
                                    _selectedAccountTransferTo != null)
                                ? MoneyText(
                                    _selectedAccountTransferTo!.balanceAt(
                                      transactionDate,
                                    ),
                                  )
                                : null,
                            onTap: () => selectAccountTransferTo(),
                            trailing: _selectedAccountTransferTo == null
                                ? const Icon(Symbols.chevron_right)
                                : null,
                            focusNode: _selectAccountTransferToFocusNode,
                          ),
                        ),
                        if (crossCurrencyTransfer)
                          Section(
                            title: "transaction.transfer.conversionRate".t(
                              context,
                            ),
                            child: ListTile(
                              title: Text(
                                "${Money(1.0, _selectedAccount!.currency).formatMoney()} = ${Money(_conversionRate, _selectedAccountTransferTo!.currency).formatMoney()}",
                              ),
                              onTap: () => inputPostConversionAmount(),
                              trailing: _selectedAccountTransferTo == null
                                  ? LeChevron()
                                  : null,
                              focusNode: _selectAccountTransferToFocusNode,
                            ),
                          ),
                      ],
                      // Category
                      if (!isTransfer)
                        Section(
                          title: _categorySectionTitleKey.t(context),
                          child: ListTile(
                            leading: _selectedCategory == null
                                ? null
                                : FlowIcon(
                                    _selectedCategory!.icon,
                                    plated: true,
                                    colorScheme: _selectedCategory!.colorScheme,
                                  ),
                            title: Text(
                              _selectedCategory?.name ??
                                  _categoryPickerTitleKey.t(context),
                            ),
                            onTap: () => selectCategory(),
                            trailing: _selectedCategory == null
                                ? const Icon(Symbols.chevron_right)
                                : null,
                          ),
                        ),
                      DescriptionSection(
                        value: _descriptionMarkdown,
                        focusNode: _descriptionFocusNode,
                        onChanged: (value) {
                          setState(() {
                            _descriptionMarkdown = value;
                          });
                        },
                      ),
                      if (_recurrence == null || !widget.isNewTransaction)
                        Section(
                          title: "transaction.date".t(context),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: Text(transactionDate.toMoment().LLL),
                                onTap: () => selectTransactionDate(),
                                leading: Icon(Symbols.calendar_month_rounded),
                                trailing: const LeChevron(),
                              ),
                              SwitchListTile(
                                title: Text("transaction.pending".t(context)),
                                secondary: Icon(
                                  Symbols.search_activity_rounded,
                                ),
                                value: _isPending,
                                onChanged: pastDuePending
                                    ? null
                                    : updatePending,
                              ),
                            ],
                          ),
                        ),

                      Section(
                        title: "transaction.recurring".t(context),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          child: _recurrence != null
                              ? SelectRecurrence(
                                  initialValue: _recurrence,
                                  onChanged: updateRecurrence,
                                  startBounds: startBounds,
                                )
                              : ListTile(
                                  leading: Icon(Symbols.repeat_rounded),
                                  title: Text(
                                    "transaction.recurring.setup".t(context),
                                  ),
                                  onTap: _setupRecurring,
                                  trailing: const LeChevron(),
                                ),
                        ),
                      ),

                      if (_currentlyEditing != null)
                        Section(
                          title: "transaction.actions".t(context),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: Icon(Symbols.content_copy_rounded),
                                title: Text("transaction.duplicate".t(context)),
                                onTap: () => _duplicate(),
                              ),
                              if (_currentlyEditing.isDeleted == true)
                                ListTile(
                                  leading: Icon(Symbols.restore_page_rounded),
                                  title: Text(
                                    "transaction.moveToTrashBin.restore".t(
                                      context,
                                    ),
                                  ),
                                  onTap: () => _restoreTransaction(),
                                ),
                              if (_currentlyEditing.isDeleted == true)
                                ListTile(
                                  leading: Icon(Symbols.delete_forever_rounded),
                                  title: Text("transaction.delete".t(context)),
                                  onTap: () => _deleteTransaction(),
                                  iconColor: context.flowColors.expense,
                                  textColor: context.flowColors.expense,
                                ),
                              if (_currentlyEditing.isDeleted != true)
                                ListTile(
                                  leading: Icon(Symbols.delete_forever_rounded),
                                  title: Text(
                                    "transaction.moveToTrashBin".t(context),
                                  ),
                                  onTap: () => _moveToTrash(),
                                ),
                              SizedBox(height: 32.0),
                              Text(
                                "${"transaction.createdDate".t(context)} ${_currentlyEditing.createdDate.format(payload: "LLL", forceLocal: true)}",
                                style: context.textTheme.bodyMedium?.semi(
                                  context,
                                ),
                              ),
                              if (UserPreferencesService()
                                  .transactionListTileShowExternalSource)
                                if (_currentlyEditing.externalProviderName
                                    case String providerName) ...[
                                  const SizedBox(height: 8.0),
                                  switch (providerName.toLowerCase()) {
                                    "siri" => const ImportedFromSiri(),
                                    _ => Text(
                                      "transaction.external.from".t(
                                        context,
                                        providerName,
                                      ),
                                      style: context.textTheme.bodyMedium?.semi(
                                        context,
                                      ),
                                    ),
                                  },
                                ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void updateTransactionType(TransactionType type) {
    if (type == _transactionType ||
        (_currentlyEditing != null && _currentlyEditing.isTransfer)) {
      return;
    }

    _transactionType = type;

    final double amountSign = switch (type) {
      TransactionType.expense => -1.0,
      _ => 1.0,
    };

    _amount = _amount.abs() * amountSign;

    final bool wantsIncome = type == TransactionType.income;
    if (_selectedCategory != null &&
        categoryIsIncome(_selectedCategory!) != wantsIncome) {
      _selectedCategory = null;
    }

    setState(() {});
  }

  Future<void> inputAmount([bool fromAutomatedFlow = false]) async {
    if (_amount == 0.0) {
      await TransitiveLocalPreferences().updateTransitiveProperties();
    }

    if (!mounted) return;

    final hideCurrencySymbol = !TransitiveLocalPreferences()
        .usesMultipleCurrencies
        .get();

    final double? result = await showModalBottomSheet<double>(
      context: context,
      builder: (context) => InputAmountSheet(
        initialAmount: _amount.abs(),
        currency: _selectedAccount?.currency,
        hideCurrencySymbol: _selectedAccount == null && hideCurrencySymbol,
        title: _transactionType.localizedNameContext(context),
        lockSign: true,
      ),
      isScrollControlled: true,
    );

    final double? resultAmount = result == null
        ? null
        : switch (_transactionType) {
            TransactionType.expense => -result.abs(),
            TransactionType.income => result.abs(),
            TransactionType.transfer => result.abs(),
          };

    _amount = resultAmount ?? _amount;

    if (!mounted) return;

    setState(() {});

    if (_conversionRate == 1.0) {
      await inputPostConversionAmount();
    }
  }

  Future<void> inputPostConversionAmount() async {
    if (!crossCurrencyTransfer) return;

    final double initialAmount = _amount * _conversionRate;

    // In the currency of [to]
    final double? postConversionAmount = await showModalBottomSheet<double>(
      context: context,
      builder: (context) => InputAmountSheet(
        initialAmount: initialAmount,
        currency: _selectedAccountTransferTo?.currency,
        overrideDecimalPrecision: 8,
        hideCurrencySymbol: false,
        title: "${Money(_amount, _selectedAccount!.currency).formatMoney()} =",
        lockSign: true,
        allowNegative: false,
      ),
      isScrollControlled: true,
    );

    if (postConversionAmount != null) {
      _conversionRate = postConversionAmount / _amount;
    }

    setState(() {});
  }

  Future<void> selectAccount([bool fromAutomatedFlow = false]) async {
    final accounts = AccountsProvider.of(context).activeAccounts;

    if (fromAutomatedFlow && accounts.isEmpty) {
      return;
    }

    final Account? result = accounts.length == 1
        ? accounts.single
        : await showModalBottomSheet<Account>(
            context: context,
            builder: (context) => SelectAccountSheet(
              accounts: accounts,
              currentlySelectedAccountId: _selectedAccount?.id,
              titleOverride: isTransfer
                  ? "transaction.transfer.from.select".t(context)
                  : null,
              showBalance: true,
              showTrailing: widget.isNewTransaction,
            ),
            isScrollControlled: true,
          );

    if (result?.id == _selectedAccountTransferTo?.id) {
      _selectedAccountTransferTo = null;
    }
    _selectedAccount = result ?? _selectedAccount;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> selectAccountTransferTo([bool fromAutomatedFlow = false]) async {
    final accounts = AccountsProvider.of(context).activeAccounts;

    final List<Account> toAccounts = accounts.where((element) {
      return element.id != _selectedAccount?.id;
    }).toList();

    if (fromAutomatedFlow && toAccounts.isEmpty) {
      return;
    }

    final Account? result = toAccounts.length == 1
        ? toAccounts.single
        : await showModalBottomSheet<Account>(
            context: context,
            builder: (context) => SelectAccountSheet(
              accounts: toAccounts,
              currentlySelectedAccountId: _selectedAccountTransferTo?.id,
              titleOverride: "transaction.transfer.to.select".t(context),
              showBalance: true,
            ),
            isScrollControlled: true,
          );

    _selectedAccountTransferTo = result ?? _selectedAccountTransferTo;
    if (mounted) {
      setState(() {});
    }

    final bool crossCurrency =
        _selectedAccount != null &&
        _selectedAccountTransferTo != null &&
        _selectedAccount!.currency != _selectedAccountTransferTo!.currency;

    if (crossCurrency && widget.isNewTransaction) {
      final ExchangeRates? rates = ExchangeRatesService()
          .getPrimaryCurrencyRates();

      if (rates != null) {
        _conversionRate = Money(
          1.0,
          _selectedAccount!.currency,
        ).convert(_selectedAccountTransferTo!.currency, rates).amount;
      }
    }
  }

  Future<bool> selectCategory([bool fromAutomatedFlow = false]) async {
    final List<Category> categories = CategoriesProvider.of(
      context,
    ).categoriesFor(_transactionType);

    if (fromAutomatedFlow && categories.isEmpty) {
      return true;
    }

    if (!fromAutomatedFlow || _selectedCategory == null) {
      final Optional<Category>? result =
          await showModalBottomSheet<Optional<Category>>(
            context: context,
            builder: (context) => SelectCategorySheet(
              currentlySelectedCategoryId: _selectedCategory?.id,
              showTrailing: widget.isNewTransaction,
              transactionType: _transactionType,
            ),
            isScrollControlled: true,
          );

      if (!mounted) return false;

      if (result != null) {
        setState(() {
          _selectedCategory = result.value;
        });
      }

      return result != null;
    }

    return false;
  }

  void selectTransactionDate() async {
    final TimeOfDay currentTimeOfDay = TimeOfDay.fromDateTime(transactionDate);

    final DateTime? result = await context.pickDate(transactionDate);

    setState(() {
      _transactionDate = result ?? _transactionDate;
    });

    _postSelectTransactionDate();

    if (!mounted || result == null) return;

    final TimeOfDay? timeResult = await showTimePicker(
      context: context,
      initialTime: currentTimeOfDay,
    );

    if (timeResult == null) return;

    setState(() {
      _transactionDate = transactionDate.copyWith(
        hour: timeResult.hour,
        minute: timeResult.minute,
        second: 0,
        microsecond: 0,
        millisecond: 0,
      );
    });

    _postSelectTransactionDate();
  }

  void updatePending(bool newPending) {
    setState(() {
      _isPending = newPending;
    });
  }

  void updateRecurrence(Recurrence? recurrence) {
    if (widget.isNewTransaction) {
      _transactionDate = recurrence?.range.from;
    }
    _recurrence = recurrence;

    if (!mounted) return;

    setState(() {});
  }

  void _postSelectTransactionDate() async {
    final bool pendingTransactionsRequireConfrimation = LocalPreferences()
        .pendingTransactions
        .requireConfrimation
        .get();

    if (!_isPending && pendingTransactionsRequireConfrimation) {
      _isPending = transactionDate.isFutureAnchored(
        Moment.now().startOfNextMinute(),
      );
      if (mounted) {
        setState(() {});
      }
    }

    // noop
    return;
  }

  bool _ensureAccountsSelected() {
    if (_selectedAccount == null) {
      context.showErrorToast(
        error: "error.transaction.missingAccount".t(context),
      );
      _selectAccountFocusNode.requestFocus();
      return false;
    }

    if (isTransfer && _selectedAccountTransferTo == null) {
      context.showErrorToast(
        error: "error.transaction.missingAccount".t(context),
      );
      _selectAccountTransferToFocusNode.requestFocus();
      return false;
    }

    return true;
  }

  void _setupRecurring() async {
    final Recurrence? result = await showModalBottomSheet(
      context: context,
      builder: (context) => SelectRecurrenceSheet(
        initialValue: _recurrence,
        startBounds: transactionDate.rangeToMax(),
      ),
    );

    _recurrence ??= result;

    setState(() {});
  }

  void _update({
    required String? formattedTitle,
    required String? formattedDescription,
  }) async {
    if (_currentlyEditing == null) return;

    RecurringUpdateMode? mode;

    final bool originalTransactionWasRecurring =
        _currentlyEditing.isRecurring && _recurringTransaction != null;

    if (originalTransactionWasRecurring) {
      final List<RecurringUpdateMode> availableModes = [
        if (_recurrence == _recurringTransaction!.recurrence)
          RecurringUpdateMode.current,
        RecurringUpdateMode.thisAndFuture,
      ];

      if (availableModes.length == 1) {
        mode = availableModes.single;
      } else {
        mode = await showModalBottomSheet(
          context: context,
          builder: (context) => SelectRecurringUpdateModeSheet(
            values: availableModes,
            title: Text("transaction.recurring.edit".t(context)),
          ),
          isScrollControlled: true,
        );
      }
    }

    assert(mode != RecurringUpdateMode.all);

    if ((originalTransactionWasRecurring && mode == null) || !mounted) return;

    final String recurringTransactionUuid =
        _recurringTransaction?.uuid ?? const Uuid().v4();

    if (_transactionType == TransactionType.transfer) {
      try {
        _selectedAccount!.transferTo(
          amount: _amount,
          title: formattedTitle,
          description: formattedDescription,
          targetAccount: _selectedAccountTransferTo!,
          createdDate: _currentlyEditing.createdDate,
          transactionDate: _transactionDate,
          extensions: _currentlyEditing.extensions
              .getOverriden(_geo, Geo.keyName)
              .data,
          isPending: _isPending,
          conversionRate: crossCurrencyTransfer ? _conversionRate : null,
          recurrence: _recurrence,
          tags: _selectedTags,
        );

        _currentlyEditing.permanentlyDelete(true);
      } catch (e, stackTrace) {
        _log.severe("Failed to update transfer transaction", e, stackTrace);
      }
    } else {
      _currentlyEditing.setCategory(_selectedCategory);
      _currentlyEditing.setAccount(_selectedAccount);
      _currentlyEditing.title = formattedTitle;
      _currentlyEditing.description = formattedDescription;
      _currentlyEditing.amount = _amount;
      _currentlyEditing.transactionDate = transactionDate;
      _currentlyEditing.isPending = _isPending;
      _currentlyEditing.setTags(_selectedTags ?? []);
      _currentlyEditing.setAttachments(_attachments);

      /// When user edits a balance amendment transaction, it is no longer a balance amendment.
      if (_currentlyEditing.subtype == TransactionSubtype.updateBalance.value) {
        _currentlyEditing.subtype = null;
      }

      final List<TransactionExtension> newExtensions = [
        ..._currentlyEditing.extensions.getOverriden(_geo, Geo.keyName).data,
      ];

      newExtensions.removeWhere((ext) => ext.key == Recurring.keyName);

      if (_recurrence != null) {
        newExtensions.add(
          Recurring(
            uuid: recurringTransactionUuid,
            initialTransactionDate: _currentlyEditing.transactionDate,
          ),
        );
      }

      _currentlyEditing.extensions = ExtensionsWrapper(newExtensions);

      FileAttachmentService().upsertManySync(_attachments ?? []);
      TransactionsService().updateOneSync(_currentlyEditing);
    }

    if (_recurringTransaction == null &&
        !originalTransactionWasRecurring &&
        _recurrence != null) {
      _recurringTransaction = RecurringTransactionsService()
          .createFromTransaction(
            identifier: _currentlyEditing,
            recurrence: _recurrence!,
            uuidOverride: recurringTransactionUuid,
            transferToAccountUuid: isTransfer
                ? _selectedAccountTransferTo?.uuid
                : null,
          );
    }

    if (originalTransactionWasRecurring &&
        mode == RecurringUpdateMode.thisAndFuture) {
      final RecurringTransaction? recurringTransaction =
          RecurringTransactionsService().findOneSync(recurringTransactionUuid);

      if (recurringTransaction == null) {
        _log.warning(
          "Failed to find recurring transaction for update. Transaction(${_currentlyEditing.uuid})",
        );
        return;
      }

      final (
        _,
        List<Transaction> futureRelatedRecurringTransactions,
      ) = await RecurringTransactionsService().findRelatedTransactionsByMode(
        _currentlyEditing,
        RecurringUpdateMode.thisAndFuture,
      );

      final List<Transaction> futureRelatedRecurringTransactionsToDelete =
          futureRelatedRecurringTransactions
              .where(
                (futureTransaction) =>
                    futureTransaction.isPending == true &&
                    futureTransaction.transactionDate.isFutureAnchored(
                      _initialTransactionDate,
                    ),
              )
              .toList();

      bool hasDeletedFutureTransaction = false;

      for (Transaction x in futureRelatedRecurringTransactionsToDelete) {
        try {
          TransactionsService().moveToBinSync(x);
          hasDeletedFutureTransaction = true;
        } catch (e, stackTrace) {
          _log.severe("Failed to move transaction to trash bin", e, stackTrace);
        }
      }

      try {
        if (hasDeletedFutureTransaction) {
          recurringTransaction.lastGeneratedTransactionDate =
              _initialTransactionDate;
        }
        recurringTransaction.template = _currentlyEditing;
        recurringTransaction.timeRange =
            _recurrence?.range ?? recurringTransaction.timeRange;
        recurringTransaction.recurrenceRules =
            _recurrence?.rules ?? recurringTransaction.recurrenceRules;
        recurringTransaction.transferToAccountUuid =
            _selectedAccountTransferTo?.uuid ??
            recurringTransaction.transferToAccountUuid;
        RecurringTransactionsService().updateSync(recurringTransaction);
      } catch (e, stackTrace) {
        _log.severe(
          "Failed to update RelatedTransaction($recurringTransactionUuid). Initiated by Transaction(${_currentlyEditing.uuid})",
          e,
          stackTrace,
        );
      }
    }

    pop();
  }

  void save() {
    if (!_ensureAccountsSelected()) return;

    final String trimmedTitle = _titleController.text.trim();
    final String? formattedTitle = trimmedTitle.isNotEmpty
        ? trimmedTitle
        : null;

    final String trimmedDescription = _descriptionMarkdown?.trim() ?? "";
    final String? formattedDescription = trimmedDescription.isNotEmpty
        ? trimmedDescription
        : null;

    if (_currentlyEditing != null) {
      return _update(
        formattedTitle: formattedTitle,
        formattedDescription: formattedDescription,
      );
    }

    final List<TransactionExtension> extensions = [?_geo];

    if (isTransfer) {
      _selectedAccount!.transferTo(
        targetAccount: _selectedAccountTransferTo!,
        amount: _amount.abs(),
        transactionDate: _transactionDate,
        title: formattedTitle,
        description: formattedDescription,
        extensions: extensions,
        isPending: _isPending,
        conversionRate: crossCurrencyTransfer ? _conversionRate : null,
        recurrence: _recurrence,
        tags: _selectedTags,
        attachments: _attachments,
        latitude: _geo?.latitude,
        longitude: _geo?.longitude,
      );
    } else {
      _selectedAccount!.createAndSaveTransaction(
        amount: _amount,
        title: formattedTitle,
        description: formattedDescription,
        category: _selectedCategory,
        transactionDate: _transactionDate,
        extensions: extensions,
        isPending: _isPending,
        recurrence: _recurrence,
        tags: _selectedTags,
        attachments: _attachments,
        latitude: _geo?.latitude,
        longitude: _geo?.longitude,
      );
    }

    pop();
  }

  bool hasChanged() {
    if (_currentlyEditing != null) {
      final bool transferToAccountDifferent =
          _currentlyEditing.isTransfer &&
          _currentlyEditing.extensions.transfer?.toAccountUuid !=
              _selectedAccountTransferTo?.uuid;

      if (transferToAccountDifferent) {
        return true;
      }

      final bool amountChanged = isTransfer
          ? _currentlyEditing.amount.abs() != _amount
          : _currentlyEditing.amount != _amount;

      return amountChanged ||
          (_currentlyEditing.title ?? "") != _titleController.text ||
          (_currentlyEditing.description ?? "") !=
              (_descriptionMarkdown ?? "") ||
          (_currentlyEditing.isPending ?? false) != _isPending ||
          _currentlyEditing.type != _transactionType ||
          _currentlyEditing.accountUuid != _selectedAccount?.uuid ||
          _currentlyEditing.categoryUuid != _selectedCategory?.uuid ||
          !setEquals(
            _selectedTags?.map((tag) => tag.uuid).toSet(),
            _currentlyEditing.tags.map((tag) => tag.uuid).toSet(),
          ) ||
          !setEquals(
            _attachments?.map((attachment) => attachment.uuid).toSet(),
            _currentlyEditing.attachments.map((file) => file.uuid).toSet(),
          ) ||
          _currentlyEditing.transactionDate != _transactionDate;
    }

    return _amount != 0 ||
        _titleController.text.isNotEmpty ||
        _descriptionMarkdown?.isNotEmpty == true ||
        _selectedAccount?.uuid != _initialAccountUuid ||
        _selectedAccountTransferTo != null ||
        _isPending ||
        (_selectedTags ?? []).isNotEmpty ||
        (_attachments ?? []).isNotEmpty ||
        _selectedCategory != null;
  }

  void _moveToTrash() async {
    if (_currentlyEditing == null || _currentlyEditing.isDeleted == true) {
      return;
    }

    final bool moved = await _currentlyEditing.moveToTrashBin(context);

    if (mounted && moved) {
      context.showToast(text: "transaction.moveToTrashBin.success".t(context));
      pop();
    }
  }

  void _restoreTransaction() async {
    if (_currentlyEditing == null || _currentlyEditing.isDeleted != true) {
      return;
    }

    _currentlyEditing.recoverFromTrashBin();

    if (mounted) {
      context.showToast(
        text: "transaction.moveToTrashBin.restore.success".t(context),
      );
      pop();
    }
  }

  void _deleteTransaction() async {
    if (_currentlyEditing == null || _currentlyEditing.isDeleted != true) {
      return;
    }

    final String txnTitle =
        _currentlyEditing.title ?? "transaction.fallbackTitle".t(context);

    final confirmation = await context.showConfirmationSheet(
      isDeletionConfirmation: true,
      title: "general.delete.confirmName".t(context, txnTitle),
    );

    if (confirmation == true) {
      _currentlyEditing.permanentlyDelete();

      if (mounted) {
        pop();
      }
    }
  }

  void _duplicate() async {
    if (_currentlyEditing == null) return;

    final int duplicate = _currentlyEditing.duplicate();

    context.showToast(text: "transaction.duplicate.success".t(context));
    await context.push("/transaction/$duplicate");
  }

  void pop() {
    FileAttachmentService().performCleanupCheck();
    if (!mounted) return;

    final NavigatorState navigator = Navigator.of(context);
    while (mounted &&
        ModalRoute.of(context)?.isCurrent != true &&
        navigator.canPop()) {
      navigator.pop();
    }
    if (mounted && context.canPop()) {
      context.pop();
    }
  }

  String get fallbackTitle {
    if (UserPreferencesService().useCategoryNameForUntitledTransactions &&
        _selectedCategory?.name != null) {
      return _selectedCategory!.name;
    }

    return switch (_transactionType) {
      TransactionType.transfer
          when _selectedAccount != null && _selectedAccountTransferTo != null =>
        "transaction.transfer.fromToTitle".t(context, {
          "from": _selectedAccount!.name,
          "to": _selectedAccountTransferTo!.name,
        }),
      _ => "transaction.fallbackTitle".t(context),
    };
  }

  TimeRange? getStartBounds() {
    if (widget.isNewTransaction || _currentlyEditing == null) {
      return TimeRange.allTime();
    }

    if (!_currentlyEditing.isRecurring) {
      return (_transactionDate ?? _currentlyEditing.transactionDate)
          .rangeToMax();
    }

    return null;
  }

  void _applyPrimaryAccount() {
    try {
      final String primaryAccountUuid =
          UserPreferencesService().primaryAccountUuid;
      _selectedAccount = AccountsService().findOneActiveSync(
        primaryAccountUuid,
      );
    } catch (_) {
      // No accounts yet; save() still validates.
    }
  }

  void _orchestrateFlow(TransactionEntryFlow flow) async {
    for (final entry in flow.actions) {
      if (!mounted) return;
      switch (entry) {
        case TransactionEntryAction.selectAccount:
        case TransactionEntryAction.selectPrimaryAccount:
          if (_selectedAccount == null) {
            _applyPrimaryAccount();
            if (mounted) setState(() {});
          }
        case TransactionEntryAction.selectCategoryOrTransferAccount:
          if (isTransfer) {
            if (flow.skipSelectedFields && _selectedAccountTransferTo != null) {
              //
            } else {
              await selectAccountTransferTo(true);
              if (flow.abandonUponActionCancelled &&
                  _selectedAccountTransferTo == null) {
                return;
              }
            }
          } else {
            if (flow.skipSelectedFields && _selectedCategory != null) {
              //
            } else {
              final bool userHandled = await selectCategory(true);
              if (flow.abandonUponActionCancelled && !userHandled) {
                return;
              }
            }
          }
        case TransactionEntryAction.inputAmount:
          if (flow.skipSelectedFields && _amount != 0.0) {
            //
          } else {
            await inputAmount(true);
            if (flow.abandonUponActionCancelled && _amount == 0.0) {
              return;
            }
          }
        case TransactionEntryAction.selectTags:
        case TransactionEntryAction.attachFiles:
          break;
        case TransactionEntryAction.inputTitle:
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (flow.skipSelectedFields) {
              if (_titleController.text.isNotEmpty) {
                return;
              }
            }

            if (context.mounted) {
              FocusScope.of(context).requestFocus(_titleFocusNode);
            }
          });
      }
    }
  }
}
