import "package:flow/data/transaction_multi_programmable_object.dart";
import "package:flow/data/transaction_programmable_object.dart";
import "package:flow/entity/budget.dart";
import "package:flow/l10n/extensions.dart";
import "package:flow/objectbox.dart";
import "package:flow/routes/account/account_edit_page.dart";
import "package:flow/routes/account_page.dart";
import "package:flow/routes/accounts_page.dart";
import "package:flow/routes/budget_detail_page.dart";
import "package:flow/routes/budget_page.dart";
import "package:flow/routes/budgets_page.dart";
import "package:flow/routes/categories_page.dart";
import "package:flow/routes/category/category_edit_page.dart";
import "package:flow/routes/category_page.dart";
import "package:flow/routes/debug/debug_icloud_page.dart";
import "package:flow/routes/debug/debug_log_page.dart";
import "package:flow/routes/debug/debug_logs_page.dart";
import "package:flow/routes/debug/debug_theme_page.dart";
import "package:flow/routes/error_page.dart";
import "package:flow/routes/export/export_history_page.dart";
import "package:flow/routes/export/export_pdf_page.dart";
import "package:flow/routes/export_options_page.dart";
import "package:flow/routes/export_page.dart";
import "package:flow/routes/home_page.dart";
import "package:flow/routes/import_page.dart";
import "package:flow/routes/import_wizard/csv.dart";
import "package:flow/routes/import_wizard/ivy.dart";
import "package:flow/routes/import_wizard/v1.dart";
import "package:flow/routes/import_wizard/v2.dart";
import "package:flow/routes/preferences/button_order_preferences_page.dart";
import "package:flow/routes/preferences/numpad_preferences_page.dart";
import "package:flow/routes/preferences/sync_preferences_page.dart";
import "package:flow/routes/preferences/theme_preferences_page.dart";
import "package:flow/routes/preferences/transfer_preferences_page.dart";
import "package:flow/routes/preferences_page.dart";
import "package:flow/routes/profile_page.dart";
import "package:flow/routes/setup/setup_accounts_page.dart";
import "package:flow/routes/setup/setup_categories_page.dart";
import "package:flow/routes/setup/setup_currency_page.dart";
import "package:flow/routes/setup/setup_onboarding_page.dart";
import "package:flow/routes/setup/setup_profile_page.dart";
import "package:flow/routes/setup/setup_profile_picture_page.dart";
import "package:flow/routes/setup_page.dart";
import "package:flow/routes/stats/budgets_overview_page.dart";
import "package:flow/routes/stats/cash_flow_page.dart";
import "package:flow/routes/stats/insights_page.dart";
import "package:flow/routes/stats/net_worth_page.dart";
import "package:flow/routes/stats/recurring_page.dart";
import "package:flow/routes/stats/spending_calendar_page.dart";
import "package:flow/routes/stats/stats_by_group_page.dart";
import "package:flow/routes/stats/wrapped_page.dart";
import "package:flow/routes/transaction_batch_import_page.dart";
import "package:flow/routes/transaction_page.dart";
import "package:flow/routes/transactions_page.dart";
import "package:flow/routes/utils/crop_square_image_page.dart";
import "package:flow/sync/export/mode.dart";
import "package:flow/sync/import/external/ivy_wallet_csv.dart";
import "package:flow/sync/import/import_csv.dart";
import "package:flow/sync/import/import_v1.dart";
import "package:flow/sync/import/import_v2.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:moment_dart/moment_dart.dart";

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

/// Sends a `/budgets/:id` route to the budgets list when the id doesn't resolve
/// to a stored budget, instead of dead-ending on the 404 error page.
///
/// The id reaches this route from three places that can all outlive the budget
/// they point at: the in-app budget alert, home-screen widget deep links
/// (`flow-mn:///budgets/:id`), and donated Siri shortcuts. A budget that was
/// deleted — or whose ObjectBox id drifted after a data reset — used to render
/// a bare "page not found". Falling back to the list keeps the entry point
/// useful rather than broken.
String? _budgetExistsOrList(BuildContext context, GoRouterState state) {
  final int? id = int.tryParse(state.pathParameters["id"] ?? "");

  if (id == null || ObjectBox().box<Budget>().get(id) == null) {
    return "/budgets";
  }

  return null;
}

final GoRouter router = GoRouter(
  navigatorKey: globalNavigatorKey,
  errorBuilder: (context, state) => ErrorPage(error: state.error?.toString()),
  routes: [
    GoRoute(path: "/", builder: (context, state) => const HomePage()),
    GoRoute(
      path: "/transaction/new",
      redirect: (context, state) {
        if (state.uri.queryParameters["json"] case String jason
            when jason.isNotEmpty) {
          return "/transaction/batch-import?json=${Uri.encodeComponent(jason)}";
        }

        return null;
      },
      pageBuilder: (context, state) {
        final TransactionProgrammableObject? params =
            TransactionProgrammableObject.fromUri(state.uri);

        return MaterialPage(
          child: TransactionPage.create(params: params),
          fullscreenDialog: true,
        );
      },
    ),
    GoRoute(
      path: "/transaction/batch-import",
      pageBuilder: (context, state) {
        final TransactionMultiProgrammableObject? multiParams =
            TransactionMultiProgrammableObject.fromUri(state.uri);

        return MaterialPage(
          child: TransactionBatchImportPage(params: multiParams),
          fullscreenDialog: true,
        );
      },
    ),
    GoRoute(
      path: "/transaction/:id",
      pageBuilder: (context, state) => MaterialPage(
        child: TransactionPage.edit(
          transactionId: int.tryParse(state.pathParameters["id"]!) ?? -1,
        ),
        fullscreenDialog: true,
      ),
    ),
    GoRoute(
      path: "/transactions",
      builder: (context, state) =>
          TransactionsPage.all(title: "transactions.all".t(context)),
    ),
    GoRoute(
      path: "/transactions/pending",
      builder: (context, state) =>
          TransactionsPage.pending(title: "transactions.pending".t(context)),
    ),
    GoRoute(
      path: "/transactions/deleted",
      builder: (context, state) =>
          TransactionsPage.deleted(title: "transaction.deleted".t(context)),
    ),
    GoRoute(
      path: "/account/new",
      builder: (context, state) => const AccountEditPage.create(),
    ),
    GoRoute(
      path: "/account/:id",
      builder: (context, state) => AccountPage(
        accountId: int.tryParse(state.pathParameters["id"]!) ?? -1,
        initialRange: TimeRange.tryParse(
          state.uri.queryParameters["range"] ?? "",
        ),
      ),
      routes: [
        GoRoute(
          path: "edit",
          pageBuilder: (context, state) => MaterialPage(
            child: AccountEditPage(
              accountId: int.tryParse(state.pathParameters["id"]!) ?? -1,
            ),
            fullscreenDialog: true,
          ),
        ),
        GoRoute(
          path: "transactions",
          builder: (context, state) => TransactionsPage.account(
            accountId: int.tryParse(state.pathParameters["id"]!) ?? -1,
            title: state.uri.queryParameters["title"],
          ),
        ),
      ],
    ),
    GoRoute(
      path: "/category/new",
      builder: (context, state) =>
          CategoryEditPage.create(isIncome: state.extra == true),
    ),
    GoRoute(
      path: "/category/:id",
      builder: (context, state) => CategoryPage(
        categoryId: int.tryParse(state.pathParameters["id"]!) ?? -1,
        initialRange: TimeRange.tryParse(
          state.uri.queryParameters["range"] ?? "",
        ),
      ),
      routes: [
        GoRoute(
          path: "edit",
          pageBuilder: (context, state) => MaterialPage(
            child: CategoryEditPage(
              categoryId: int.tryParse(state.pathParameters["id"]!) ?? -1,
            ),
            fullscreenDialog: true,
          ),
        ),
      ],
    ),
    GoRoute(
      path: "/categories",
      builder: (context, state) => const CategoriesPage(),
    ),
    GoRoute(
      path: "/accounts",
      builder: (context, state) => const AccountsPage(),
    ),
    GoRoute(path: "/budgets", builder: (context, state) => const BudgetsPage()),
    GoRoute(
      path: "/budgets/new",
      builder: (context, state) => const BudgetPage.create(),
    ),
    GoRoute(
      path: "/budgets/:id",
      redirect: _budgetExistsOrList,
      builder: (context, state) => BudgetDetailPage(
        budgetId: int.tryParse(state.pathParameters["id"]!) ?? -1,
      ),
    ),
    GoRoute(
      path: "/budgets/:id/edit",
      redirect: _budgetExistsOrList,
      builder: (context, state) =>
          BudgetPage(budgetId: int.tryParse(state.pathParameters["id"]!) ?? -1),
    ),
    GoRoute(
      path: "/preferences",
      builder: (context, state) => const PreferencesPage(),
      routes: [
        GoRoute(
          path: "numpad",
          builder: (context, state) => const NumpadPreferencesPage(),
        ),
        GoRoute(
          path: "transfer",
          builder: (context, state) => const TransferPreferencesPage(),
        ),
        GoRoute(
          path: "transactionButtonOrder",
          builder: (context, state) => const ButtonOrderPreferencesPage(),
        ),
        GoRoute(
          path: "theme",
          builder: (context, state) => const ThemePreferencesPage(),
        ),
        GoRoute(
          path: "sync",
          builder: (context, state) => const SyncPreferencesPage(),
        ),
      ],
    ),
    GoRoute(path: "/profile", builder: (context, state) => const ProfilePage()),
    GoRoute(
      path: "/profile/:id",
      builder: (context, state) => ProfilePage(
        profileId: int.tryParse(state.pathParameters["id"]!) ?? -1,
      ),
    ),
    GoRoute(
      path: "/utils/cropsquare",
      pageBuilder: (context, state) {
        return switch (state.extra) {
          CropSquareImagePageProps props => MaterialPage(
            child: CropSquareImagePage.fromProps(props: props),
            fullscreenDialog: true,
          ),
          _ => throw const ErrorPage(
            error:
                "Invalid state. Pass [CropSquareImagePageProps] object to `extra` prop",
          ),
        };
      },
    ),
    GoRoute(
      path: "/exportOptions",
      builder: (context, state) => const ExportOptionsPage(),
    ),
    GoRoute(
      path: "/import",
      builder: (context, state) {
        return ImportPage(
          setupMode: state.uri.queryParameters["setupMode"] == "true",
        );
      },
    ),
    GoRoute(
      path: "/import/wizard/v1",
      builder: (context, state) {
        if (state.extra case ImportV1 importV1) {
          return ImportWizardV1Page(
            importer: importV1,
            setupMode: state.uri.queryParameters["setupMode"] == "true",
          );
        }

        return ErrorPage(error: "error.sync.invalidBackupFile".t(context));
      },
    ),
    GoRoute(
      path: "/import/wizard/v2",
      builder: (context, state) {
        if (state.extra case ImportV2 importV2) {
          return ImportWizardV2Page(
            importer: importV2,
            setupMode: state.uri.queryParameters["setupMode"] == "true",
          );
        }

        return ErrorPage(error: "error.sync.invalidBackupFile".t(context));
      },
    ),
    GoRoute(
      path: "/import/wizard/csv",
      builder: (context, state) {
        if (state.extra case ImportCSV importCSV) {
          return CSVImportWizardPage(
            importer: importCSV,
            setupMode: state.uri.queryParameters["setupMode"] == "true",
          );
        }

        return ErrorPage(error: "error.sync.invalidBackupFile".t(context));
      },
    ),
    GoRoute(
      path: "/import/wizard/external/ivy",
      builder: (context, state) {
        if (state.extra case IvyWalletCsvImporter ivyWalletCsvImporter) {
          return IvyWalletImportWizardPage(
            importer: ivyWalletCsvImporter,
            setupMode: state.uri.queryParameters["setupMode"] == "true",
          );
        }

        return ErrorPage(error: "error.sync.invalidBackupFile".t(context));
      },
    ),
    GoRoute(
      path: "/export/history",
      builder: (context, state) => const ExportHistoryPage(),
    ),
    GoRoute(
      path: "/export/:type",
      builder: (context, state) {
        if (state.pathParameters["type"] == "pdf" && state.extra == null) {
          return ExportPdfPage();
        }

        return ExportPage(
          ExportMode.tryParse(state.pathParameters["type"] ?? "zip") ??
              ExportMode.zip,
          options: state.extra,
        );
      },
    ),
    GoRoute(
      path: "/import",
      builder: (context, state) => ImportPage(
        setupMode: state.uri.queryParameters["setupMode"] == "true",
      ),
    ),
    GoRoute(
      path: "/setup",
      builder: (context, state) => const SetupPage(),
      routes: [
        GoRoute(
          path: "choose",
          builder: (context, state) => const SetupOnboardingPage(),
        ),
        GoRoute(
          path: "currency",
          builder: (context, state) => const SetupCurrencyPage(),
        ),
        GoRoute(
          path: "accounts",
          builder: (context, state) => const SetupAccountsPage(),
        ),
        GoRoute(
          path: "categories",
          builder: (context, state) => SetupCategoriesPage(
            standalone: state.uri.queryParameters["standalone"] == "true",
            selectAll: state.uri.queryParameters["selectAll"] != "false",
          ),
        ),
        GoRoute(
          path: "profile",
          builder: (context, state) => const SetupProfilePage(),
        ),
        GoRoute(
          path: "profile/photo",
          builder: (context, state) =>
              SetupProfilePhotoPage(profileImagePath: state.extra as String),
        ),
      ],
    ),
    GoRoute(
      path: "/stats/category",
      builder: (context, state) {
        final TimeRange? initialRange = TimeRange.tryParse(
          state.uri.queryParameters["range"] ?? "",
        );

        return StatsByGroupPage(byCategory: true, initialRange: initialRange);
      },
    ),
    GoRoute(
      path: "/stats/account",
      builder: (context, state) {
        final TimeRange? initialRange = TimeRange.tryParse(
          state.uri.queryParameters["range"] ?? "",
        );

        return StatsByGroupPage(byCategory: false, initialRange: initialRange);
      },
    ),
    GoRoute(
      path: "/_debug/theme",
      builder: (context, state) => DebugThemePage(),
    ),
    GoRoute(
      path: "/stats/insights",
      builder: (context, state) => const InsightsPage(),
    ),
    GoRoute(
      path: "/stats/net-worth",
      builder: (context, state) => const NetWorthPage(),
    ),
    GoRoute(
      path: "/stats/wrapped",
      builder: (context, state) => const WrappedPage(),
    ),
    GoRoute(
      path: "/stats/recurring",
      builder: (context, state) => const RecurringPage(),
    ),
    GoRoute(
      path: "/stats/calendar",
      builder: (context, state) => const SpendingCalendarPage(),
    ),
    GoRoute(
      path: "/stats/cash-flow",
      builder: (context, state) => const CashFlowPage(),
    ),
    GoRoute(
      path: "/stats/budgets",
      builder: (context, state) => const BudgetsOverviewPage(),
    ),
    GoRoute(
      path: "/_debug/iCloud",
      builder: (context, state) => DebugICloudPage(),
    ),
    GoRoute(path: "/_debug/logs", builder: (context, state) => DebugLogsPage()),
    GoRoute(
      path: "/_debug/logs/view",
      builder: (context, state) {
        if (state.extra case String path) {
          return DebugLogPage(path: path);
        }

        return ErrorPage(error: "Provide path as route extra");
      },
    ),
  ],
);
