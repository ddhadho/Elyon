# Elyon

Flutter companion app for the [2red2blue](https://github.com/ddhadho/2red2blue) home automation daemon.

---

## Requirements

- Flutter 3.19+
- A running 2red2blue daemon on your local network
- Home Assistant instance (managed by the daemon)

## Setup

```bash
flutter pub get
flutter run
```

On first launch, enter your daemon address, HA long-lived access token, and a name for the home. These are stored securely on the device.

---

## What it can do

- **Home screen** — live device grid showing current state, confidence level, and safe default warnings
- **Manual control** — tap a device card to toggle it (on/off, locked/unlocked). Command is sent via `POST /command` and polled until confirmed or failed
- **Activity screen** — scrollable event log from `GET /events` with human-readable translations
- **Rules screen** — list all automation rules, enable/disable them, view full rule detail (trigger, conditions, actions)
- **Rule editor** — edit rule name, priority, conflict group, and enabled state via `PUT /rules/:id`
- **Device discovery** — browse all HA entities, add new devices directly from the app via `POST /devices`. Daemon writes to `devices.toml` on save
- **Settings** — change daemon connection, disconnect, access device discovery
- **Confidence indicators** — 5-dot display mirroring the daemon's confidence decay model. Devices on safe default show a warning

## What it cannot do yet

- **Rule builder** — creating new rules from scratch requires editing `rules.toml` directly and reloading with `SIGUSR1`. UI builder is planned for V2
- **Remote access** — the app only works on the same local network as the daemon. Tailscale support is planned for V2
- **Push notifications** — power cut and command failure alerts are not yet implemented
- **Auth** — the daemon does not yet validate the Bearer token. Any client on the local network can reach it. Auth middleware is a known gap before pilot handoff
- **Offline cache** — if the daemon is unreachable the app shows an error rather than cached state. Planned for V2
- **Hot-reload of new devices** — after adding a device via discovery, the daemon must be restarted to activate it
- **iOS builds** — requires a macOS machine with Xcode

---

## Architecture

```
lib/
├── main.dart
├── router.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart       # Dio HTTP client + auth interceptor
│   │   └── sse_service.dart      # SSE connection + heartbeat monitor
│   ├── config/
│   │   └── app_config.dart       # Secure storage for host, port, token, owner name
│   ├── models/
│   │   ├── device.dart           # Device metadata + kinds
│   │   ├── device_state.dart     # Confidence model, getEffective() mirrors Rust
│   │   ├── event_summary.dart    # Human-readable event translations
│   │   └── rule.dart             # Full rule model with trigger, conditions, actions
│   └── providers/
│       ├── api_providers.dart    # Riverpod providers for all endpoints
│       └── sse_provider.dart     # SSE event listener, invalidates providers on push
├── features/
│   ├── activity/
│   │   └── activity_screen.dart
│   ├── connection/
│   │   └── connection_screen.dart
│   ├── discovery/
│   │   └── discovery_screen.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   │       └── device_card.dart
│   ├── rules/
│   │   ├── rules_screen.dart
│   │   └── rule_detail_screen.dart
│   └── settings/
│       └── settings_screen.dart
└── shared/
    ├── theme/
    │   └── app_theme.dart        # Dark theme + AppColors
    └── widgets/
        └── confidence_dots.dart  # 5-dot confidence indicator
``````

---

## State management

Riverpod. Every daemon endpoint has a corresponding `FutureProvider`. The SSE stream
is managed by `SseNotifier` which invalidates the relevant providers when the daemon
pushes an event — device state, commands, power events. The UI rebuilds automatically.

---

## Daemon API used

| Endpoint | Used for |
|---|---|
| `GET /state` | Device state map on load + connection verification |
| `GET /devices` | Device metadata (name, kind, writable) |
| `POST /command` | Manual device control |
| `GET /commands` | Command confirmation polling |
| `GET /events` | Activity screen |
| `GET /rules` | Rules list + full rule objects |
| `PUT /rules/:id` | Rule editor |
| `POST /rules/:id/enable` | Rule toggle |
| `POST /rules/:id/disable` | Rule toggle |
| `GET /ha/entities` | Device discovery |
| `POST /devices` | Add device from discovery |
| `GET /reconciliation` | Boot recovery status |

---

## Known gaps (pre-pilot)

| Gap | Priority |
|---|---|
| Auth middleware on daemon — Bearer token not validated | Before pilot handoff |
| HA token stored in app — should move to `POST /setup` on daemon | Before multi-home |
| Offline cache — shows error when daemon unreachable | V2 |
| Remote access via Tailscale | V2 |
| Push notifications | V2 |
| Rule builder UI | V2 |
| Hot-reload new devices without daemon restart | V2 |

---

## Platforms

| Platform | Status |
|---|---|
| Android | ✅ |
| Linux desktop | ✅ |
| Web | ✅ `flutter run -d chrome` |
| iOS | Requires macOS build machine |

---

## Connection

The connection screen is an installer tool — enter the daemon address and credentials
once on setup day. The homeowner lands directly on the home screen on every subsequent
launch. Credentials are stored in the OS secure keystore via `flutter_secure_storage`.

The daemon IP is a local network address (`http://192.168.x.x:7000`). Assign a static
DHCP lease on your router so the address does not change between sessions.
