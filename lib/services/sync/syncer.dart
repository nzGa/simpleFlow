import "dart:developer";
import "dart:io";

import "package:spendly/entity/backup_entry.dart";
import "package:path/path.dart";

class SyncerItem {
  final String path;
  final DateTime? updatedAt;

  DateTime? get inferredBackupDate {
    try {
      final [...rest, date, time] = basename(path).split("_");

      final RegExpMatch ymd = RegExp(
        r"(?<year>\d+)[-.](?<month>\d+)[-.](?<date>\d+)",
      ).firstMatch(date)!;
      final RegExpMatch hms = RegExp(
        r"(?<hour>\d+)[-.](?<minute>\d+)[-.](?<second>\d+)",
      ).firstMatch(time)!;

      return DateTime(
        int.parse(ymd.namedGroup("year")!),
        int.parse(ymd.namedGroup("month")!),
        int.parse(ymd.namedGroup("date")!),
        int.parse(hms.namedGroup("hour")!),
        int.parse(hms.namedGroup("minute")!),
        int.parse(hms.namedGroup("second")!),
      );
    } catch (e) {
      log("Error parsing backup date", error: e);
      return null;
    }
  }

  const SyncerItem({required this.path, required this.updatedAt});
}

abstract class Syncer {
  /// Returns whether the file was uploaded
  Future<bool> put(BackupEntry entry, {Function(double)? onProgress});

  /// Returns the count of files deleted
  Future<int> purge({Duration? maxAge, int? keepCount});

  /// Returns whether the file was deleted
  Future<bool> delete(String name);
  Future<List<SyncerItem>> list();
  Future<SyncerItem?> get(String name);
  Future<File?> download(SyncerItem item, {Function(double)? onProgress});

  bool get syncing;
}
