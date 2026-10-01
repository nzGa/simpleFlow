import "package:spendly/entity/backup_entry.dart";
import "package:spendly/l10n/extensions.dart";
import "package:spendly/logging.dart";
import "package:spendly/sync/export.dart";
import "package:spendly/sync/export/mode.dart";
import "package:spendly/utils/utils.dart";
import "package:spendly/widgets/export/export_success.dart";
import "package:spendly/widgets/general/spinner.dart";
import "package:flutter/material.dart";
import "package:moment_dart/moment_dart.dart";

class ExportPage extends StatefulWidget {
  final ExportMode mode;
  final dynamic options;

  const ExportPage(this.mode, {super.key, this.options});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  String? filePath;

  dynamic error;
  bool done = false;

  double progress = 0.0;

  @override
  void initState() {
    super.initState();

    runExport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("sync.export".t(context, widget.mode.name))),
      body: SafeArea(child: buildChild(context)),
    );
  }

  Widget buildChild(BuildContext context) {
    if (!done) {
      return const Spinner.center();
    }

    if (filePath == null) {
      return Center(
        child: Text(error?.toString() ?? "error.sync.exportFailed".t(context)),
      );
    }

    return ExportSuccess(
      mode: widget.mode,
      shareFn: showShareSheet,
      filePath: filePath!,
    );
  }

  Future<void> runExport() async {
    try {
      final result = await export(
        mode: widget.mode,
        showShareDialog: false,
        type: BackupEntryType.manual,
        options: widget.options,
      );

      filePath = result.filePath;
    } catch (e, stackTrace) {
      error = e;
      syncLogger.severe(
        "(export page ${widget.mode}) runExport() at UI level has failed",
        e,
        stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() {
          done = true;
        });
      }
    }
  }

  Future<void> showShareSheet(BuildContext context) async {
    await context
        .showFileShareSheet(
          subject: "sync.export.save.shareTitle".t(context, {
            "type": widget.mode.name,
            "date": Moment.now().lll,
          }),
          filePath: filePath!,
        )
        .then((savedPath) {
          if (savedPath == null || !isDesktop()) {
            return;
          }
          if (!context.mounted) return;

          context.showToast(
            text: "sync.export.savedTo".t(context, {"path": savedPath}),
          );
        })
        .catchError((error) {
          if (context.mounted) {
            context.showErrorToast(error: error?.toString());
          }
        });
  }
}
