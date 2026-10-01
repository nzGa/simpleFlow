import "package:spendly/data/transactions_filter/pending_time_range.dart";
import "package:spendly/l10n/extensions.dart";
import "package:spendly/l10n/named_enum.dart";
import "package:spendly/prefs/local_preferences.dart";
import "package:spendly/services/user_preferences.dart";
import "package:spendly/widgets/general/frame.dart";
import "package:spendly/widgets/general/info_text.dart";
import "package:spendly/widgets/general/list_header.dart";
import "package:flutter/material.dart";

class PendingTransactionPreferencesPage extends StatefulWidget {
  const PendingTransactionPreferencesPage({super.key});

  @override
  State<PendingTransactionPreferencesPage> createState() =>
      _PendingTransactionPreferencesPageState();
}

class _PendingTransactionPreferencesPageState
    extends State<PendingTransactionPreferencesPage> {
  @override
  Widget build(BuildContext context) {
    final PendingTimeRange pendingTransactionsHomeTimeframe =
        UserPreferencesService().homePendingTransactionsTimeRange;
    final bool pendingTransactionsRequireConfrimation = LocalPreferences()
        .pendingTransactions
        .requireConfrimation
        .get();
    final bool pendingTransactionsUpdateDateUponConfirmation =
        LocalPreferences().pendingTransactions.updateDateUponConfirmation.get();

    return Scaffold(
      appBar: AppBar(
        title: Text("preferences.transactions.pending".t(context)),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              const SizedBox(height: 16.0),
              Frame(
                child: InfoText(
                  child: Text(
                    "preferences.transactions.pending.requireConfirmation.description"
                        .t(context),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              ListHeader(
                "preferences.transactions.pending.homeTimeframe".t(context),
              ),
              const SizedBox(height: 8.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Wrap(
                  spacing: 12.0,
                  runSpacing: 8.0,
                  children: [
                    ...PendingTimeRange.presets.map(
                      (value) => FilterChip(
                        showCheckmark: false,
                        key: ValueKey(value),
                        label: Text(
                          value.localizedNameContext(
                            context,
                            value.futureDuration?.inDays,
                          ),
                        ),
                        onSelected: (bool selected) => selected
                            ? updatePendingTransactionsHomeTimeframe(value)
                            : null,
                        selected: value == pendingTransactionsHomeTimeframe,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              CheckboxListTile(
                title: Text(
                  "preferences.transactions.pending.requireConfirmation".t(
                    context,
                  ),
                ),
                value: pendingTransactionsRequireConfrimation,
                onChanged: updatePendingTransactionsRequireConfrimation,
              ),
              if (pendingTransactionsRequireConfrimation)
                CheckboxListTile(
                  title: Text(
                    "preferences.transactions.pending.updateDateUponConfirmation"
                        .t(context),
                  ),
                  subtitle: Text(
                    "preferences.transactions.pending.updateDateUponConfirmation.description"
                        .t(context),
                  ),
                  value: pendingTransactionsUpdateDateUponConfirmation,
                  onChanged: updatePendingTransactionsConfirmationDate,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void updatePendingTransactionsHomeTimeframe(PendingTimeRange newValue) async {
    UserPreferencesService().homePendingTransactionsTimeRange = newValue;

    if (mounted) setState(() {});
  }

  void updatePendingTransactionsRequireConfrimation(
    bool? requirePendingTransactionConfrimation,
  ) async {
    if (requirePendingTransactionConfrimation == null) return;

    await LocalPreferences().pendingTransactions.requireConfrimation.set(
      requirePendingTransactionConfrimation,
    );

    if (mounted) setState(() {});
  }

  void updatePendingTransactionsConfirmationDate(bool? newValue) async {
    if (newValue == null) return;

    await LocalPreferences().pendingTransactions.updateDateUponConfirmation.set(
      newValue,
    );

    if (mounted) setState(() {});
  }
}
