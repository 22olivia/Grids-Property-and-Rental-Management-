# RESIVYN — Real Estate & Community OS

A Flutter implementation of the 21-screen RESIVYN mobile spec
(`prompt screen22.txt`), running entirely on in-memory mock data. No backend,
no network dependency, no configuration — install and explore.

## Running it

```bash
flutter run                     # on a connected device or emulator
flutter build apk --release     # release APK → build/app/outputs/flutter-apk/
flutter test                    # 83 widget + interaction tests
flutter analyze                 # zero issues
```

Requires Flutter 3.22.3 (Dart 3.4.4). The Android build uses Gradle 8.9 /
AGP 8.3.2 / Kotlin 1.9.24 so it works with the JDK 21 bundled in Android
Studio.

## Getting around the app

The login screen (screen 10) is the entry point. Pick a role and sign in —
each one lands on its own surface:

| Role | Destination |
|---|---|
| Visitor | Tab shell: Home / Search / Saved / Community / Profile |
| Tenant | Tenant Dashboard (06) |
| Owner | Owner Dashboard (07) |
| Maintainer | Maintenance Dashboard (05) |
| Super Admin | Platform Dashboard (04) |

**"Browse all screens"** at the bottom of the login screen opens a developer
index listing all 21 screens, so any screen can be opened directly without
walking the navigation flow.

## Screen map

| # | Screen | File |
|---|---|---|
| 01 | Property Floor Plan | `lib/screens/s01_floor_plan.dart` |
| 02 | Support & Contact Center | `lib/screens/s02_support_center.dart` |
| 03 | Notifications | `lib/screens/s03_notifications.dart` |
| 04 | Super Admin Dashboard | `lib/screens/s04_admin_dashboard.dart` |
| 05 | Maintenance Dashboard | `lib/screens/s05_maintenance_dashboard.dart` |
| 06 | Tenant Dashboard | `lib/screens/s06_tenant_dashboard.dart` |
| 07 | Owner Dashboard | `lib/screens/s07_owner_dashboard.dart` |
| 08 | Luxury Villa Details | `lib/screens/s08_villa_details.dart` |
| 09 | Search Properties | `lib/screens/s09_search.dart` |
| 10 | Login / Role Selection | `lib/screens/s10_login.dart` |
| 11 | Home | `lib/screens/s11_home.dart` |
| 12 | Property Details (full) | `lib/screens/s12_property_details.dart` |
| 13 | Property Gallery | `lib/screens/s13_gallery.dart` |
| 14 | Sell Your Property | `lib/screens/s14_sell_property.dart` |
| 15 | About RESIVYN | `lib/screens/s15_about.dart` |
| 16 | Contact Us | `lib/screens/s16_contact.dart` |
| 17 | Choose Your Plan | `lib/screens/s17_plans.dart` |
| 18 | Privacy Policy | `lib/screens/s18_s19_legal.dart` |
| 19 | Terms & Conditions | `lib/screens/s18_s19_legal.dart` |
| 20 | Ticket Details | `lib/screens/s20_ticket_details.dart` |
| 21 | Profile / Settings | `lib/screens/s21_profile.dart` |

Screens 18 and 19 share one parameterised `LegalScreen` — same structure,
different copy. `lib/screens/supporting.dart` holds the Saved and Community
tabs, which the spec's bottom navigation needs but does not itself define.

## Design system

Everything visual comes from `lib/core/theme/tokens.dart` — navy `#0B2348`,
teal `#00A99D`, an 8px spacing scale, 20–26px card radii and soft diffuse
shadows. Screens compose the shared widgets in `lib/widgets/` rather than
styling anything locally, which is what keeps 21 screens looking like one app.

Charts (line, bar, donut) are hand-rolled `CustomPainter`s in
`lib/widgets/charts.dart`, so there are no charting dependencies to version.
In fact the app has **zero third-party packages** — `pubspec.yaml` pulls in
nothing beyond Flutter itself.

## Swapping in a real backend

Screens never touch data directly. They call abstract repositories:

```
lib/data/repositories/repositories.dart   # the contracts
lib/data/mock/mock_repositories.dart      # in-memory implementations (current)
lib/core/service_locator.dart             # where implementations are chosen
```

To go live, write `ApiPropertyRepository implements PropertyRepository` (and
friends), then change the assignments in `Services`. No screen code changes.
The mocks deliberately return after a ~220ms delay so loading states are
already exercised against realistic timing.

## Images

Property and profile imagery loads from Unsplash over the network. Every image
sits on top of a deterministic gradient placeholder, so the app looks
intentional offline too — useful when testing on a device with no connection.

## Tests

- `test/screens_test.dart` — pumps all 23 screens three ways: normal render,
  scrolled to the bottom, and on a cramped 360×640dp viewport. Catches
  overflow and layout regressions.
- `test/interaction_test.dart` — drives real flows: role-based sign-in
  routing, tab switching, saving a property, search filtering, the 5-step
  sell form, ticket replies, and paying rent.
- `test/test_http.dart` — serves a 1×1 PNG for network images so image
  failures can't masquerade as layout failures.
