import "package:spendly/l10n/extensions.dart";
import "package:spendly/reports/interval_flow_report.dart";
import "package:flutter/material.dart";

extension IntervalReportL10n on IntervalFlowReport {
  String averageTitle(BuildContext context) {
    if (interval == const Duration(hours: 1)) {
      return "tabs.stats.intervalReport.averages@hour".t(context);
    } else if (interval == const Duration(days: 1)) {
      return "tabs.stats.intervalReport.averages@day".t(context);
    } else if (interval == const Duration(days: 7)) {
      return "tabs.stats.intervalReport.averages@week".t(context);
    } else if (interval == const Duration(days: 30)) {
      return "tabs.stats.intervalReport.averages@month".t(context);
    } else if (interval == const Duration(days: 365)) {
      return "tabs.stats.intervalReport.averages@year".t(context);
    } else {
      return "avg, per (${interval.inSeconds} seconds)".t(context);
    }
  }
}
