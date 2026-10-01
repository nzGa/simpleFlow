import "dart:async";

import "package:spendly/data/flow_notification_payload.dart";
import "package:spendly/entity/transaction.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:logging/logging.dart";

final Logger _log = Logger("NotificationsService");

class NotificationsService {
  static NotificationsService? _instance;

  static bool get schedulingSupported => false;

  bool _ready = false;
  bool get ready => _ready;

  bool? _available;
  bool get available => _available == true;

  final List<Function(NotificationResponse)> _registeredCallbacks = [];

  NotificationAppLaunchDetails? notificationAppLaunchDetails;

  factory NotificationsService() =>
      _instance ??= NotificationsService._internal();

  NotificationsService._internal();

  void addCallback(Function(NotificationResponse) callback) {
    _registeredCallbacks.add(callback);
  }

  void removeCallback(Function(NotificationResponse) callback) {
    _registeredCallbacks.remove(callback);
  }

  Future<void> initialize() async {
    _available = false;
    notificationAppLaunchDetails = null;
    _ready = true;
    _log.fine("OS scheduled notifications are disabled");
  }

  Future<List<PendingNotificationRequest>> fetchAllNotification() async {
    return <PendingNotificationRequest>[];
  }

  Future<void> cancelAllNotifications() async {}

  Future<void> scheduleForPlannedTransaction(
    Transaction transaction, [
    Duration? earlyReminder,
  ]) async {}

  Future<void> clearPayloadlessNotifications() async {}

  Future<void> clearByType(FlowNotificationPayloadItemType type) async {}

  Future<void> scheduleDailyReminders(Duration time) async {}

  Future<void> debugSchedule(DateTime scheduleAt) async {}

  void debugShow() async {}

  void requestPermissions() async {}

  Future<bool?> hasPermissions() async => false;
}
