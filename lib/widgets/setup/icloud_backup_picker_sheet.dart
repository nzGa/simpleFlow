import "package:spendly/l10n/flow_localizations.dart";
import "package:spendly/services/sync/syncer.dart";
import "package:spendly/utils/extensions.dart";
import "package:spendly/widgets/general/directional_chevron.dart";
import "package:spendly/widgets/general/flow_icon.dart";
import "package:spendly/widgets/general/modal_sheet.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:moment_dart/moment_dart.dart";
import "package:path/path.dart" as path;

/// Pops with [SyncerItem] when a backup is selected.
class ICloudBackupPickerSheet extends StatefulWidget {
  final List<SyncerItem>? backups;

  const ICloudBackupPickerSheet({super.key, required this.backups});

  @override
  State<ICloudBackupPickerSheet> createState() =>
      _ICloudBackupPickerSheetState();
}

class _ICloudBackupPickerSheetState extends State<ICloudBackupPickerSheet> {
  @override
  Widget build(BuildContext context) {
    final List<SyncerItem> eligibleItems = (widget.backups ?? [])
        .where((item) => item.inferredBackupDate != null)
        .toList();

    return ModalSheet.scrollable(
      title: Text("setup.onboarding.recoverICloudBackup".t(context)),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eligibleItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "setup.onboarding.recoverICloudBackup.noBackups".t(context),
                    textAlign: TextAlign.center,
                  ),
                ),
              ...eligibleItems.map(
                (backup) => ListTile(
                  leading: FlowIcon(backup.path.backupExtensionIcon),
                  title: Text(backup.inferredBackupDate!.toMoment().lll),
                  subtitle: Text(path.extension(backup.path).substring(1)),
                  onTap: () => context.pop(backup),
                  trailing: LeChevron(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
