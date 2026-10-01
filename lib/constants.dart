import "package:flutter/foundation.dart";
import "package:latlong2/latlong.dart";

String? downloadedFrom;

String appVersion = "0.0.0";
const bool debugBuild = false;

bool get flowDebugMode => kDebugMode || debugBuild;

final Uri website = Uri.parse("https://flow.gege.mn");
final Uri guideUrl = Uri.parse("https://flow.gege.mn/docs");
final Uri flowGitHubRepoLink = Uri.parse("https://github.com/nzGa/simpleFlow");

const double sukhbaatarSquareCenterLat = 47.918828;
const double sukhbaatarSquareCenterLong = 106.917604;

const String appleAppStoreId = "6477741670";

final Uri csvImportTemplateUrl = Uri.parse(
  "https://docs.google.com/spreadsheets/d/1wxdJ1T8PSvzayxvGs7bVyqQ9Zu0DPQ1YwiBLy1FluqE/edit?usp=sharing",
);

const LatLng sukhbaatarSquareCenter = LatLng(
  sukhbaatarSquareCenterLat,
  sukhbaatarSquareCenterLong,
);

const String iOSAppGroupId = "group.com.nzga.spendly";
