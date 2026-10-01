import "package:spendly/data/setup/default_accounts.dart";
import "package:spendly/services/user_preferences.dart";
import "package:spendly/widgets/general/spinner.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

/// Kept as a route so old onboarding stacks still resolve. The account
/// picker is skipped; a default primary account is created if needed.
class SetupAccountsPage extends StatefulWidget {
  const SetupAccountsPage({super.key});

  @override
  State<SetupAccountsPage> createState() => _SetupAccountsPageState();
}

class _SetupAccountsPageState extends State<SetupAccountsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _skip());
  }

  Future<void> _skip() async {
    await ensureDefaultAccount(UserPreferencesService().primaryCurrency);
    if (!mounted) return;
    context.pushReplacement("/setup/categories");
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Spinner.center());
  }
}
