# smarthome

Flutter app for the [2red2blue](https://github.com/ddhadho/2red2blue) home automation daemon.

## Requirements

- Flutter 3.19+
- A running 2red2blue daemon on your local network

## Setup

```bash
flutter pub get
flutter run
```

On first launch, go to **Settings** and enter your daemon's IP and port.

## Architecture

```
lib/
├── main.dart
├── router.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart
│   │   └── sse_service.dart
│   ├── config/
│   │   └── app_config.dart
│   ├── models/
│   │   ├── device.dart
│   │   ├── device_state.dart
│   │   ├── event_summary.dart
│   │   └── rule.dart
│   └── providers/
│       ├── api_providers.dart
│       └── sse_provider.dart
├── features/
│   ├── activity/
│   │   └── activity_screen.dart
│   ├── connection/
│   │   └── connection_screen.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   │       └── device_card.dart
│   ├── rules/
│   │   └── rules_screen.dart
│   └── settings/               ← new folder
│       └── settings_screen.dart ← new file
└── shared/
    ├── theme/
    │   └── app_theme.dart
    └── widgets/
        └── confidence_dots.dart
```

## State management

Riverpod. All daemon state flows through `daemonStateProvider` (WebSocket stream).
Filtered views (`lightsProvider`, `locksProvider`) derive from it.

## Write support

Toggle controls are currently disabled — they're wired and ready but wait on the
daemon's `POST /device/:id/command` endpoint landing. When it does, uncomment
the `onChanged`/`onTap` callbacks in `lights_page.dart` and `locks_page.dart`.

## Platforms

| Platform | Status |
|---|---|
| Android | ✅ |
| Linux desktop | ✅ |
| Web | ✅ (run `flutter run -d chrome`) |
| iOS | Requires macOS build machine |