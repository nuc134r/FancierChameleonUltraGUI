# FancierChameleonUltraGUI (fork)

Fork of GameTec-live/ChameleonUltraGUI with a redesigned, phone-first UI. Flutter app in `chameleonultragui/`.
The UX audit and plan: https://claude.ai/artifact/B3GwzD9b8QZXHQ1zKDYvH4

## Branches
- `better-ui` — default branch with all fork work; base new work on it and merge back into it.
- `main` — pure mirror of upstream's `main`. Never commit fork changes there; upstream comes into the fork
  by merging `main` into `better-ui` (see docs/FORK_RELEASING.md).

## Stay mergeable with upstream
Upstream is merged into `better-ui` regularly, so:
- Put new UI in **new files under `chameleonultragui/lib/fork/`**; reuse upstream pages, dialogs and helpers.
- Keep edits to upstream files small and marked with a `// Fork:` comment. Current ones: `lib/main.dart`
  (MaterialApp uses the fork shell/theme), `lib/sharedprefsprovider.dart` (dark theme default),
  `lib/gui/page/write_card.dart` (`initialCard`), `android/app/build.gradle` (`applicationId`).
- Don't edit `lib/l10n/*.arb` (Crowdin-managed upstream). Fork strings go in `lib/fork/strings.dart`
  (en + ru, English fallback); reuse existing `AppLocalizations` keys where they fit.
- Don't edit upstream workflows; fork CI is `.github/workflows/fork-release.yml` (see docs/FORK_RELEASING.md).

## Layout of lib/fork
- `shell.dart` — bottom bar (Device, Scan, Library, Tools; rail at >= 840 dp), Settings gear, `pushDeviceRoute`
  (routes closed on disconnect). Upstream pages that are not redesigned yet are wrapped in `_LegacyPage`.
- `theme.dart` — dark PCB-gold theme, `monoStyle` (RobotoMono for data only), `SectionLabel`, `EmptyState`.
- `library/` — Library (Cards | Keys tabs), Card page (Info | Data | Keys), shared actions.

## Look
Dark by default, PCB gold accent (#D9A93A), 6 px corners, monospace only for UIDs/keys/hex, uppercase mono
section labels (`HF · 13.56 MHZ`). Overflow menus instead of icon rows; one primary action per screen.

## Commands (run in chameleonultragui/)
```bash
flutter analyze
flutter test $(ls test/*_test.dart | grep -v recovery_test.dart)   # recovery_test needs `flutter build linux` first
flutter build linux --release   # quick visual check; turn on Settings › "Activate emulated device" for a fake Demo device
```
