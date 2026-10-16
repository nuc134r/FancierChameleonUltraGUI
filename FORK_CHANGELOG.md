# Changelog (fork)

Release notes for this fork's GitHub releases. Each `## <version>` section becomes the notes of
the release tagged `v<version>` (see docs/FORK_RELEASING.md). Upstream's history is in its own releases.

## 2.1.0

- Device tab without a Chameleon: explains how to connect, lists found devices with a Connect
  button, offers demo mode; Bluetooth connecting shows inline.
- Connected Device tab: status header (model, connection, battery, firmware), Emulate | Read switch,
  firmware update banner, and the 8 slots as a list with the active one highlighted.
- Slot page: HF and LF sides with on/off switch, Load from library, Edit, View data, Clear and
  Save to library.
- Card page: Load to slot.
- Device settings as a full page grouped into Firmware, Buttons, LEDs, Bluetooth, Power and
  Danger zone.

## 2.0.0

- Android app id is now `io.nuc134r.chameleon`, so the fork installs next to the upstream app.
- Signed APKs are published to GitHub releases.
- New navigation: bottom bar with Device, Scan, Library and Tools; Settings moved behind the gear.
- Library replaces Saved Cards: Cards and Keys tabs, search, HF/LF filter, folder breadcrumbs,
  one ⋮ menu per row, Undo after deleting.
- Card page replaces the card dialog: Info, Data (hex/ASCII dump) and Keys tabs; Write to tag button.
- Dark theme by default with a PCB gold accent.
