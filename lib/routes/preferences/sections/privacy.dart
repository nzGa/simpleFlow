import "package:spendly/l10n/extensions.dart";
import "package:spendly/routes/preferences_page.dart";
import "package:spendly/services/user_preferences.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons_flow/symbols.dart";

class Privacy extends StatefulWidget {
  const Privacy({super.key});

  @override
  State<Privacy> createState() => _PrivacyState();
}

class _PrivacyState extends State<Privacy> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        SwitchListTile(
          secondary: const Icon(Symbols.password_rounded),
          title: Text("preferences.privacy.maskAtStartup".t(context)),
          value: UserPreferencesService().privacyModeUponLaunch,
          onChanged: updatePrivacyMode,
        ),
      ],
    );
  }

  void updatePrivacyMode(bool? newPrivacyMode) async {
    if (newPrivacyMode == null) return;

    UserPreferencesService().privacyModeUponLaunch = newPrivacyMode;

    if (!mounted) return;

    PreferencesPage.of(context).reload();
    setState(() {});
  }
}
