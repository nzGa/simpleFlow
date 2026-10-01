import "package:spendly/data/setup/default_categories.dart";
import "package:spendly/entity/category.dart";
import "package:spendly/l10n/extensions.dart";
import "package:spendly/objectbox.dart";
import "package:spendly/objectbox/objectbox.g.dart";
import "package:spendly/prefs/local_preferences.dart";
import "package:spendly/services/exchange_rates.dart";
import "package:spendly/services/user_preferences.dart";
import "package:spendly/widgets/categories/no_categories.dart";
import "package:spendly/widgets/category_card.dart";
import "package:spendly/widgets/general/button.dart";
import "package:spendly/widgets/general/spinner.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:material_symbols_icons_flow/symbols.dart";

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  QueryBuilder<Category> qb() =>
      ObjectBox().box<Category>().query().order(Category_.createdDate);

  @override
  void initState() {
    super.initState();

    if (TransitiveLocalPreferences().usesNonPrimaryCurrency.get()) {
      ExchangeRatesService().getPrimaryCurrencyRates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("categories".t(context))),
      body: SafeArea(
        child: StreamBuilder<List<Category>>(
          stream: qb()
              .watch(triggerImmediately: true)
              .map((event) => event.find()),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Spinner.center();
            }

            final List<Category> categories = snapshot.requireData;

            final bool showPresetsButton = !getCategoryPresets().every(
              (preset) =>
                  categories.any((category) => category.uuid == preset.uuid),
            );

            return switch (categories.length) {
              0 => const NoCategories(),
              _ => ValueListenableBuilder(
                valueListenable: ExchangeRatesService().exchangeRatesCache,
                builder: (context, exchangeRatesCache, _) {
                  return ValueListenableBuilder(
                    valueListenable: UserPreferencesService().valueNotifier,
                    builder: (context, userPreferences, child) {
                      final bool excludeTransfersInTotal =
                          userPreferences.excludeTransfersFromFlow;
                      final String primaryCurrency =
                          UserPreferencesService().primaryCurrency;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          spacing: 16.0,
                          crossAxisAlignment: .stretch,
                          children: [
                            Button(
                              onTap: () => context.push("/category/new"),
                              leading: Icon(Symbols.add_rounded),
                              child: Text("category.new".t(context)),
                            ),
                            if (showPresetsButton)
                              Button(
                                leading: Icon(Symbols.category_rounded),
                                onTap: () {
                                  context.push(
                                    "/setup/categories?standalone=true&selectAll=false",
                                  );
                                },
                                child: Text(
                                  "categories.addFromPresets".t(context),
                                ),
                              ),
                            const Divider(),
                            ...categories.map(
                              (category) => CategoryCard(
                                category: category,
                                excludeTransfersInTotal:
                                    excludeTransfersInTotal,
                                rates: exchangeRatesCache?.get(primaryCurrency),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            };
          },
        ),
      ),
    );
  }
}
