import "package:spendly/constants.dart";
import "package:spendly/data/actionable_nofications/actionable_notification.dart";
import "package:spendly/l10n/extensions.dart";
import "package:spendly/utils/utils.dart";
import "package:spendly/widgets/internal_notifications/internal_notification_list_tile.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons_flow/material_symbols_icons.dart";

class StarOnGithubNotification extends StatelessWidget {
  final StarOnGitHub notification;
  final VoidCallback? onDismiss;

  const StarOnGithubNotification({
    super.key,
    required this.notification,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ActionableNotificationListTile(
      onDismiss: onDismiss,
      icon: notification.icon,
      title: "tabs.home.reminders.starOnGitHub".t(context),
      subtitle: "⭐⭐⭐⭐⭐",
      action: TextButton.icon(
        onPressed: () {
          if (onDismiss != null) {
            onDismiss!();
          }
          openUrl(flowGitHubRepoLink);
        },
        label: Text("GitHub"),
        icon: Icon(Symbols.open_in_new_rounded),
      ),
    );
  }
}
