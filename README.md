# Spendly

Personal simple expense tracker app.
Modified version of [Flow](https://github.com/flow-mn/flow) (September 2026). It remains free software under the [GNU General Public License v3](./LICENSE).

Original copyright: Copyright (C) 2024 Batmend Ganbaatar and authors of Flow.
See [NOTICE](./NOTICE) for attribution and a summary of what changed.

This is not the Flow app on the App Store or Google Play. The original authors
are not responsible for this project. There is no store listing for this fork:
clone the repo and run it locally (see [Development](#development)).

## What it is

Accounts, transactions, categories, and spending stats. Build from source
(macOS; Linux and Windows untested). Web is not supported (ObjectBox).

Compared with upstream Flow, the app no longer includes Eny, in-app
support/community and IAP, maps and geo tagging, attachments / camera /
Markdown notes, tags and budgets in the UI, or OS scheduled notifications.
Existing backup data for those features is still imported.

## Features

- Day-to-day tracking with a simple UI
- Accounts in ARS, BRL, EUR, or USD
- Categories and spending stats
- No account or server of its own[^1]
- Data stays on device
  - No trackers, no analytics
  - Recoverable backups (ZIP/JSON)
  - Export CSV and PDFs
- UI languages: English, Spanish, Portuguese

## Development

Personal project. See [CONTRIBUTING.md](./CONTRIBUTING.md) if you still want to open a pull request.

### Prerequisites

- [Flutter](https://flutter.dev/) (latest stable)
- JDK 17 or later to build for Android
- [Xcode](https://developer.apple.com/xcode/) to build for iOS/macOS

Desktop builds need the same native deps as Flutter. See
[https://docs.flutter.dev/platform-integration](https://docs.flutter.dev/platform-integration).

### Run

```sh
flutter pub get
flutter run
```

That launches on the connected device or the desktop target you select
(`flutter devices`). On a phone this is a sideloaded debug build, not a store
install.

### Testing

```sh
flutter test
```

On Linux (including CI), install ObjectBox’s native library first:

```sh
bash <(curl -s https://raw.githubusercontent.com/objectbox/objectbox-dart/main/install.sh)
```

macOS usually does not need that step. If the installer changes, see
[ObjectBox’s Flutter getting started](https://docs.objectbox.io/getting-started#add-objectbox-to-your-project).

## Original Flow

Upstream: [flow-mn/flow](https://github.com/flow-mn/flow).
To support the original maintainer:
[buymeacoffee.com/sadespresso](https://buymeacoffee.com/sadespresso).

[^1]: Works without an account or our own backend. Network is only used for
exchange rates when you have more than one currency, and for iCloud backups
if you turn that on (Apple platforms).
