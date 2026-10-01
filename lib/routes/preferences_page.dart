import "package:spendly/l10n/flow_localizations.dart";
import "package:spendly/prefs/local_preferences.dart";
import "package:spendly/routes/preferences/language_selection_sheet.dart";
import "package:spendly/routes/preferences/sections/lock_app.dart";
import "package:spendly/routes/preferences/sections/privacy.dart";
import "package:spendly/services/local_auth.dart";
import "package:spendly/services/user_preferences.dart";
import "package:spendly/theme/color_themes/registry.dart";
import "package:spendly/theme/flow_color_scheme.dart";
import "package:spendly/theme/names.dart";
import "package:spendly/widgets/general/directional_chevron.dart";
import "package:spendly/widgets/general/list_header.dart";
import "package:spendly/widgets/sheets/select_currency_sheet.dart";
import "package:flutter/material.dart" hide Flow;
import "package:go_router/go_router.dart";
import "package:logging/logging.dart";
import "package:material_symbols_icons_flow/symbols.dart";

final Logger _log = Logger("PreferencesPage");

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => PreferencesPageState();

  static PreferencesPageState of(BuildContext context) {
    return context.findAncestorStateOfType<PreferencesPageState>()!;
  }
}

class PreferencesPageState extends State<PreferencesPage> {
  bool _currencyBusy = false;
  bool _languageBusy = false;

  bool _showLockApp = false;

  @override
  void initState() {
    super.initState();

    LocalAuthService.initialize()
        .then((_) {
          _showLockApp = LocalAuthService.available;

          if (mounted) {
            setState(() {});
          }
        })
        .catchError((_) {
          _log.warning("Failed to initialize local auth service");
        });
  }

  @override
  Widget build(BuildContext context) {
    final FlowColorScheme currentTheme = getTheme(
      UserPreferencesService().themeName,
    );

    final String currentPrimaryCurrency =
        UserPreferencesService().primaryCurrency;

    return Scaffold(
      appBar: AppBar(title: Text("preferences".t(context))),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: Text("preferences.sync".t(context)),
              leading: const Icon(Symbols.sync_rounded),
              onTap: () => _pushAndRefreshAfter("/preferences/sync"),
              trailing: const LeChevron(),
            ),
            ListTile(
              title: Text("preferences.language".t(context)),
              leading: const Icon(Symbols.language_rounded),
              onTap: () => _updateLanguage(),
              subtitle: Text(FlowLocalizations.of(context).locale.endonym),
              trailing: const LeChevron(),
            ),
            ListTile(
              title: Text("preferences.primaryCurrency".t(context)),

              leading: const Icon(Symbols.universal_currency_alt_rounded),
              onTap: () => _updatePrimaryCurrency(),
              subtitle: Text(currentPrimaryCurrency),
              trailing: const LeChevron(),
            ),
            ListTile(
              title: Text("preferences.transfer".t(context)),
              leading: const Icon(Symbols.sync_alt_rounded),
              onTap: () => _pushAndRefreshAfter("/preferences/transfer"),
              subtitle: Text(
                "preferences.transfer.description".t(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const LeChevron(),
            ),
            const SizedBox(height: 24.0),
            ListHeader("preferences.appearance".t(context)),
            const SizedBox(height: 8.0),
            ListTile(
              title: Text("preferences.theme".t(context)),
              leading: currentTheme.isDark
                  ? const Icon(Symbols.dark_mode_rounded)
                  : const Icon(Symbols.light_mode_rounded),
              subtitle: Text(
                themeNames[currentTheme.name] ?? currentTheme.name,
              ),
              onTap: _openTheme,
              trailing: const LeChevron(),
            ),
            const SizedBox(height: 24.0),
            ListHeader("preferences.privacy".t(context)),
            const SizedBox(height: 8.0),
            const Privacy(),
            if (_showLockApp) ...[const SizedBox(height: 8.0), const LockApp()],
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  void _updateLanguage() async {
    if (_languageBusy || !mounted) return;

    setState(() {
      _languageBusy = true;
    });

    try {
      Locale current =
          LocalPreferences().localeOverride.get() ??
          FlowLocalizations.supportedLocales.first;

      final selected = await showModalBottomSheet<Locale>(
        context: context,
        builder: (context) => LanguageSelectionSheet(currentLocale: current),
        isScrollControlled: true,
      );

      if (selected != null) {
        await LocalPreferences().localeOverride.set(selected);
      }
    } finally {
      _languageBusy = false;
    }
  }

  void _updatePrimaryCurrency() async {
    if (_currencyBusy) return;

    setState(() {
      _currencyBusy = true;
    });

    try {
      final String current = UserPreferencesService().primaryCurrency;

      final selected = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SelectCurrencySheet(currentlySelected: current),
        isScrollControlled: true,
      );

      if (selected != null) {
        UserPreferencesService().primaryCurrency = selected;
      }
    } finally {
      _currencyBusy = false;

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _pushAndRefreshAfter(String path) async {
    await context.push(path);

    // Rebuild to update description text
    if (mounted) setState(() {});
  }

  void _openTheme() async {
    await context.push("/preferences/theme");

    final bool themeChangesAppIcon =
        UserPreferencesService().themeChangesAppIcon;

    trySetAppIcon(
      themeChangesAppIcon
          ? allThemes[UserPreferencesService().themeName]?.iconName
          : null,
    );

    // Rebuild to update description text
    if (mounted) setState(() {});
  }

  void reload() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }
}
