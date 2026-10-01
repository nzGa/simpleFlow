import "package:spendly/entity/backup_entry.dart";
import "package:spendly/services/sync/icloud_syncer.dart";
import "package:spendly/utils/utils.dart";
import "package:icloud_storage/icloud_storage.dart";

extension BackupEntryExtension on BackupEntry {
  ICloudFile? get correspondingICloudFile {
    try {
      final List<ICloudFile> files = ICloudSyncer().filesCache.value;

      return files.firstWhereOrNull(
        (file) => file.relativePath == ICloudSyncer().resolvePath(filePath),
      );
    } catch (e) {
      return null;
    }
  }

  /// Whether the file can be uploaded to iCloud.
  bool get canUploadToCloud {
    if (correspondingICloudFile != null) return false;
    if (!ICloudSyncer.supported || !ICloudSyncer().syncing) return false;

    try {
      return correspondingICloudFile == null;
    } catch (e) {
      return true;
    }
  }
}
